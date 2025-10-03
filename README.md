# KipuBank - Smart Contract

![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## 📋 Descripción

KipuBank es un contrato inteligente desarrollado en Solidity que simula un banco descentralizado simple. Permite a los usuarios depositar y retirar Ether (ETH) con restricciones de seguridad implementadas, incluyendo límites por transacción y capacidad global del banco.

### Características Principales

- **Bóvedas Personales**: Cada usuario tiene su propio saldo de ETH
- **Depósitos Limitados**: Capacidad máxima global configurable (`bankCap`)
- **Retiros Controlados**: Límite fijo por transacción (`withdrawLimit`)
- **Seguridad Avanzada**: Protección contra reentrancy y validaciones exhaustivas
- **Eventos y Estadísticas**: Registro completo de operaciones
- **Control de Acceso**: Funciones administrativas restringidas al owner

## 🏗️ Arquitectura del Contrato

### Variables Clave
- `withdrawLimit` (inmutable): Máximo ETH por retiro
- `bankCap` (inmutable): Capacidad total del banco
- `balances`: Saldos individuales por dirección
- `totalDeposits`: ETH total actualmente en el banco
- `depositCount` / `withdrawCount`: Contadores de operaciones

### Funciones Principales

| Función | Visibilidad | Descripción |
|---------|------------|-------------|
| `deposit()` | external payable | Depositar ETH en bóveda personal |
| `withdraw(amount)` | external | Retirar ETH (limitado por `withdrawLimit`) |
| `balances(address)` | public view | Consultar saldo de cualquier usuario |
| `getTotalDeposits()` | external view | Ver total de ETH en el banco |
| `getTotalDepositsCount()` | external view | Ver número de depósitos |
| `getTotalWithdrawalsCount()` | external view | Ver número de retiros |

### Seguridad Implementada
- ✅ **Protección Reentrancy**: Modificador `noReentrancy`
- ✅ **Patrón CEI**: Checks-Effects-Interactions correctamente implementado
- ✅ **Errores Personalizados**: 6 tipos de errores específicos
- ✅ **Transferencias Seguras**: Uso de `.call()` para envío de ETH
- ✅ **Funciones Públicas**: Acceso transparente a estadísticas

## 🚀 Despliegue en Remix IDE

### Paso 1: Preparación
1. Abrir [Remix IDE](https://remix.ethereum.org)
2. Conectar MetaMask a **Sepolia Testnet**
3. Asegurarse de tener ETH de prueba ([Faucet Sepolia](https://sepoliafaucet.com))

### Paso 2: Compilación
1. Crear archivo `KipuBank.sol` en carpeta `contracts/`
2. Copiar el código del contrato
3. Ir a "Solidity Compiler" → Versión `0.8.20+`
4. Click "Compile KipuBank.sol"

### Paso 3: Despliegue
1. Ir a "Deploy & Run Transactions"
2. Environment: "Injected Provider - MetaMask"
3. Configurar parámetros del constructor:

```
_withdrawLimit: 100000000000000000    (0.1 ETH en wei)
_bankCap:      500000000000000000    (0.5 ETH en wei)
```

4. Click "Deploy" → Confirmar en MetaMask
5. ✅ ¡Contrato desplegado!

## 🔧 Interacción con el Contrato

### Realizar Depósitos
```javascript
// En Remix:
// 1. Ir a "VALUE" → Ingresar cantidad en wei
// 2. Click en botón "deposit" (naranja)
// 3. Confirmar transacción en MetaMask

Ejemplos de valores:
0.5 ETH = 500000000000000000 wei
0.1 ETH = 100000000000000000 wei
```

### Realizar Retiros
```javascript
// En función "withdraw":
// 1. Ingresar cantidad en wei (máximo = withdrawLimit)
// 2. Click "withdraw" → Confirmar en MetaMask

Validaciones:
- amount <= withdrawLimit ✓
- amount <= balances[msg.sender] ✓
```

### Consultas Públicas (Sin Gas)
```javascript
// Ver saldo personal
balances("0xTuDireccion") → returns saldo en wei

// Ver versión del contrato
VERSION() → returns "1.0.0"

// Ver estadísticas del banco
getTotalDeposits() → ETH total en el banco
getTotalDepositsCount() → Número de depósitos
getTotalWithdrawalsCount() → Número de retiros
```

## 📊 Eventos y Monitoreo

### Eventos Emitidos
- `Deposit(address indexed account, uint256 amount)`
- `Withdraw(address indexed account, uint256 amount)`

Los eventos aparecen en la consola de Remix después de cada transacción exitosa y pueden usarse para tracking de operaciones.

## 🛡️ Errores Personalizados

| Error | Cuando Ocurre |
|-------|---------------|
| `ExceedsBankCap` | Depósito supera capacidad del banco |
| `ExceedsWithdrawLimit` | Retiro supera límite por transacción |
| `InsufficientBalance` | Saldo insuficiente para retiro |
| `TransferFailed` | Fallo en envío de ETH |
| `ReentrancyDetected` | Intento de ataque detectado |
| `InvalidWithdrawLimit` | Parámetro constructor inválido |
| `InvalidBankCap` | Parámetro constructor inválido |

## 🧪 Casos de Prueba Recomendados

1. **✅ Depósito válido**: Depositar 0.5 ETH → Success
2. **❌ Exceder bankCap**: Intentar depositar más del límite total
3. **✅ Retiro válido**: Retirar 0.3 ETH con saldo suficiente
4. **❌ Exceder withdrawLimit**: Intentar retirar más del límite
5. **❌ Saldo insuficiente**: Retirar más ETH del disponible
6. **✅ Consultar estadísticas**: Usar funciones `getTotalDeposits()`, etc.

## 🔗 Valores de Referencia

### Conversiones Wei ↔ ETH
- 1 ETH = 1,000,000,000,000,000,000 wei (18 decimales)
- 0.1 ETH = 100,000,000,000,000,000 wei
- 0.01 ETH = 10,000,000,000,000,000 wei

### Configuraciones Sugeridas
- **Testing**: withdrawLimit = 1 ETH, bankCap = 10 ETH
- **Desarrollo**: withdrawLimit = 0.1 ETH, bankCap = 1 ETH

## ⚠️ Nota sobre Transparencia en Blockchain

**Importante**: Las variables marcadas como `private` en Solidity **no son realmente privadas** en blockchain. Solo restringen el acceso programático, pero cualquier persona puede leer el storage del contrato directamente.

### ¿Por qué usar getters públicos?
Las funciones de consulta son públicas porque:
- **Transparencia total**: Los datos son públicos de todas formas
- **Facilidad de uso**: Más fácil para dApps que leer storage directamente
- **Requerimientos educativos**: Demostrar funciones `external view`
- **Honestidad técnica**: No simular privacidad que no existe

**Ventaja**: Elimina complejidad innecesaria y es más honesto sobre las capacidades de blockchain.

## 📄 Licencia

MIT License - Ver `LICENSE` para detalles completos.

---

**⚠️ Importante**: Este contrato es para propósitos educativos. Realizar auditoría de seguridad antes de uso en producción.

