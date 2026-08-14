import { BadRequestException } from '@nestjs/common';
import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional, IsString } from 'class-validator';
import { existsSync, mkdirSync } from 'fs';
import { extname } from 'path';
import { randomUUID } from 'crypto';
import { diskStorage } from 'multer';

const MAX_FILE_BYTES = 12 * 1024 * 1024;
const MAX_FILES = 30;

const ALLOWED = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/gif',
  'image/heic',
  'image/heif',
]);

function uploadDir() {
  return process.env.UPLOAD_DIR || './uploads';
}

function extFrom(file: { originalname: string; mimetype: string }) {
  const fromName = extname(file.originalname || '').toLowerCase();
  if (fromName && fromName.length <= 6) return fromName;
  if (file.mimetype === 'image/png') return '.png';
  if (file.mimetype === 'image/webp') return '.webp';
  if (file.mimetype === 'image/gif') return '.gif';
  return '.jpg';
}

export const fotoUploadOptions = {
  storage: diskStorage({
    destination: (_req, _file, cb) => {
      const dir = uploadDir();
      if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
      cb(null, dir);
    },
    filename: (_req, file, cb) => {
      cb(null, `${randomUUID()}${extFrom(file)}`);
    },
  }),
  limits: { fileSize: MAX_FILE_BYTES, files: MAX_FILES },
  fileFilter: (
    _req: unknown,
    file: { mimetype: string },
    cb: (err: Error | null, accept: boolean) => void,
  ) => {
    if (!file.mimetype || !ALLOWED.has(file.mimetype.toLowerCase())) {
      cb(new BadRequestException('Envie apenas imagens (jpg, png, webp)'), false);
      return;
    }
    cb(null, true);
  },
};

export function publicFotoUrl(filename: string) {
  return `/uploads/${filename}`;
}

export class AdicionarFotosDto {
  @IsOptional()
  @IsString()
  tipo?: string;

  @IsOptional()
  @IsString()
  legenda?: string;

  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true' || value === '1')
  @IsBoolean()
  publico?: boolean;
}
