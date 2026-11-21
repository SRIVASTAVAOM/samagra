import express from 'express';
import request from 'supertest';
import routes from '../src/modules/materials/materials.routes';
import { CloudinaryService } from '../src/services/cloudinary.service';

jest.mock('../src/config/env.config', () => ({ env: { MAX_UPLOAD_SIZE_BYTES: '1024' } }));
jest.mock('../src/modules/materials/materials.controller', () => ({
  MaterialsController: new Proxy({}, { get: () => jest.fn() }),
}));
jest.mock('../src/middlewares/auth.middleware', () => ({
  authenticateToken: (req: express.Request, res: express.Response, next: express.NextFunction) =>
    req.headers.authorization ? next() : res.sendStatus(401),
}));
jest.mock('../src/services/cloudinary.service', () => ({
  CloudinaryService: { isConfigured: jest.fn(), uploadBuffer: jest.fn() },
}));

const app = express().use('/materials', routes);
const upload = (bytes: Buffer) => request(app).post('/materials/attachments')
  .set('Authorization', 'test').type('application/octet-stream').send(bytes);

beforeEach(() => {
  jest.resetAllMocks();
  jest.mocked(CloudinaryService.isConfigured).mockReturnValue(true);
});

test.each([Buffer.from('%PDF-1.7'), Buffer.from([0xff, 0xd8, 0xff, 0xd9])])(
  'forwards the selected bytes and returns the storage receipt', async bytes => {
    const url = 'https://res.cloudinary.com/test/image/upload/file';
    jest.mocked(CloudinaryService.uploadBuffer).mockResolvedValue({ url, publicId: 'file' });
    const res = await upload(bytes).expect(201);
    expect(res.body.data.url).toBe(url);
    expect(CloudinaryService.uploadBuffer).toHaveBeenCalledWith(bytes, expect.any(String));
  });

test('rejects unauthenticated, unsupported and unavailable uploads', async () => {
  await request(app).post('/materials/attachments').expect(401);
  await upload(Buffer.from('invalid')).expect(415);
  jest.mocked(CloudinaryService.isConfigured).mockReturnValue(false);
  await upload(Buffer.from('%PDF-')).expect(503);
  expect(CloudinaryService.uploadBuffer).not.toHaveBeenCalled();
});
