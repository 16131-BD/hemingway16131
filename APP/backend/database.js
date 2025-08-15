const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'info', 'warn'] : ['error'],
});

prisma.$connect()
  .then(() => {
    console.log("Conectado a la BD");
  })
  .catch((error) => {
    console.log("Error al conectar a la BD => ", error);
    process.exit(1);
  });

module.exports = prisma;