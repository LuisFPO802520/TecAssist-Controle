-- AlterTable
ALTER TABLE "Notificacao" ADD COLUMN     "servicoId" INTEGER;

-- CreateIndex
CREATE INDEX "Notificacao_servicoId_idx" ON "Notificacao"("servicoId");

-- AddForeignKey
ALTER TABLE "Notificacao" ADD CONSTRAINT "Notificacao_servicoId_fkey" FOREIGN KEY ("servicoId") REFERENCES "Servico"("id") ON DELETE SET NULL ON UPDATE CASCADE;
