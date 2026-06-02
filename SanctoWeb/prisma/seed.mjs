import prismaPkg from "@prisma/client";
import bcrypt from "bcryptjs";

const { PrismaClient } = prismaPkg;

const prisma = new PrismaClient();

async function main() {
  const adminPassword = await bcrypt.hash("admin123", 12);

  await prisma.user.upsert({
    where: { cpf: "00000000000" },
    update: {},
    create: {
      fullName: "Administrador SANCTO",
      cpf: "00000000000",
      email: "admin@sanctopdv.local",
      phone: "(11) 90000-0000",
      role: "ADMINISTRADOR",
      active: true,
      passwordHash: adminPassword,
    },
  });

  const category = await prisma.category.upsert({
    where: { name: "Ingressos" },
    update: {},
    create: { name: "Ingressos", active: true },
  });

  await prisma.product.upsert({
    where: { barcode: "ING-60" },
    update: {},
    create: {
      name: "Ingresso 60 minutos",
      description: "Ingresso padrão 60 minutos",
      barcode: "ING-60",
      internalCode: "ING60",
      categoryId: category.id,
      salePrice: 45,
      promoPrice: 40,
      costPrice: 0,
      stock: 9999,
      minStock: 10,
      unit: "UN",
      type: "Ingresso",
      ncm: "99999999",
      cfop: "5102",
      cstOrCsosn: "102",
      icmsRate: 18,
      pisRate: 1.65,
      cofinsRate: 7.6,
      active: true,
      sellByCommand: true,
    },
  });

  await prisma.fiscalConfig.upsert({
    where: { id: "default-fiscal-config" },
    update: {},
    create: {
      id: "default-fiscal-config",
      environment: "HOMOLOGACAO",
      series: 1,
      nextNfeNumber: 1,
      nextNfceNumber: 1,
    },
  });

  const pkg = await prisma.partyPackage.findFirst({ where: { name: "Pacote 1" } });
  if (!pkg) {
    await prisma.partyPackage.createMany({
      data: [
        { name: "Pacote 1", maxGuests: 10, weekdayPrice: 900, weekendPrice: 1200, description: "Pacote básico" },
        { name: "Pacote 2", maxGuests: 20, weekdayPrice: 1400, weekendPrice: 1700, description: "Pacote intermediário" },
        { name: "Pacote 3", maxGuests: 30, weekdayPrice: 2100, weekendPrice: 2500, description: "Pacote premium" },
      ],
    });
  }

  console.log("Seed concluído com sucesso.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
