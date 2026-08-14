import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpStatus,
} from '@nestjs/common';
import { MulterError } from 'multer';

@Catch(MulterError)
export class MulterExceptionFilter implements ExceptionFilter {
  catch(exception: MulterError, host: ArgumentsHost) {
    const res = host.switchToHttp().getResponse();
    const message =
      exception.code === 'LIMIT_FILE_SIZE'
        ? 'Arquivo muito grande. Máximo 12 MB por foto.'
        : 'Falha no envio da foto.';
    res.status(HttpStatus.BAD_REQUEST).json({ statusCode: 400, message });
  }
}
