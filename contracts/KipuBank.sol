// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KipuBank
 * @dev A simple bank contract that allows users to deposit and withdraw ETH with certain restrictions.
 * @notice This contract demonstrates basic Solidity concepts and security best practices.
 */
contract KipuBank {
    /**
     * @notice Variables de estado que almacenan información sobre el banco
     */
    
    /// @notice Versión del contrato KipuBank
    string public constant VERSION = "1.0.0";
    
    // Variables de estado
    /// @notice Número total de operaciones de depósito realizadas
    uint256 private depositCount;
    
    /// @notice Número total de operaciones de retiro realizadas
    uint256 private withdrawCount;
    
    /// @notice Cantidad máxima que puede retirarse en una transacción
    uint256 private immutable withdrawLimit;
    
    /// @notice Límite total de ETH que puede depositarse en el banco
    uint256 private immutable bankCap;
    
    /// @notice Suma total de ETH depositado actualmente en el banco
    uint256 private totalDeposits;
    
    /// @notice Mapeo de direcciones a sus saldos depositados
    mapping(address => uint256) public balances;
    
    /// @notice Dirección del propietario del contrato
    address private immutable owner;
    
    /// @notice Variable para prevenir ataques de reentrancy
    bool private locked;
    
    // Eventos
    /// @notice Emitido cuando un usuario realiza un depósito
    /// @param account Dirección del usuario que deposita
    /// @param amount Cantidad de ETH depositada
    event Deposit(address indexed account, uint256 amount);
    
    /// @notice Emitido cuando un usuario realiza un retiro
    /// @param account Dirección del usuario que retira
    /// @param amount Cantidad de ETH retirada
    event Withdraw(address indexed account, uint256 amount);
    
    // Errores personalizados
    /// @notice Error lanzado cuando un depósito excede la capacidad del banco
    /// @param attempted Cantidad que se intentó depositar
    /// @param available Espacio disponible en el banco
    error ExceedsBankCap(uint256 attempted, uint256 available);
    
    /// @notice Error lanzado cuando un retiro excede el límite por transacción
    /// @param attempted Cantidad que se intentó retirar
    /// @param limit Límite máximo por retiro
    error ExceedsWithdrawLimit(uint256 attempted, uint256 limit);
    
    /// @notice Error lanzado cuando un usuario intenta retirar más de su saldo
    /// @param available Saldo disponible del usuario
    /// @param required Cantidad solicitada para retiro
    error InsufficientBalance(uint256 available, uint256 required);
    
    /// @notice Error lanzado cuando falla una transferencia de ETH
    error TransferFailed();
    
    /// @notice Error lanzado cuando se detecta un intento de reentrancy
    error ReentrancyDetected();
    
    /// @notice Error lanzado cuando el límite de retiro en el constructor es inválido
    error InvalidWithdrawLimit();
    
    /// @notice Error lanzado cuando la capacidad del banco en el constructor es inválida
    error InvalidBankCap();
    
    // Modificador para evitar reentradas
    /// @notice Modificador que previene ataques de reentrancy
    modifier noReentrancy() {
        if (locked) {
            revert ReentrancyDetected();
        }
        locked = true;
        _;
        locked = false;
    }
    


    /**
     * @dev Constructor que establece los límites y el propietario del contrato.
     * @param _withdrawLimit Límite de retiro por transacción en wei.
     * @param _bankCap Límite global de depósitos en wei.
     */
    constructor(uint256 _withdrawLimit, uint256 _bankCap) {
        if (_withdrawLimit == 0) {
            revert InvalidWithdrawLimit();
        }
        if (_bankCap == 0) {
            revert InvalidBankCap();
        }
        withdrawLimit = _withdrawLimit;
        bankCap = _bankCap;
        owner = msg.sender;
    }

    /**
     * @dev Permite a los usuarios depositar ETH en su bóveda personal.
     * @notice Requiere que el depósito no exceda el límite global del banco.
     */
    function deposit() external payable noReentrancy {
        if (totalDeposits + msg.value > bankCap) {
            revert ExceedsBankCap(totalDeposits + msg.value, bankCap - totalDeposits);
        }
        
        // Effects
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        ++depositCount;
        
        // Event emission
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Permite a los usuarios retirar ETH de su bóveda personal.
     * @notice Requiere que el retiro no exceda el límite por transacción y que el usuario tenga saldo suficiente.
     * @param amount Cantidad de ETH a retirar en wei.
     * @custom:security Protegido contra reentrancy y overflows
     */
    function withdraw(uint256 amount) external noReentrancy {
        // Checks
        if (amount > withdrawLimit) {
            revert ExceedsWithdrawLimit(amount, withdrawLimit);
        }
        
        uint256 userBalance = _checkBalance(msg.sender);
        if (userBalance < amount) {
            revert InsufficientBalance(userBalance, amount);
        }
        
        // Effects
        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        ++withdrawCount;
        emit Withdraw(msg.sender, amount);
        
        // Interactions
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    /**
     * @dev Función de vista pública para consultar el saldo total del banco.
     * @return El saldo total de ETH actualmente depositado en el banco.
     * @notice Esta función puede ser llamada por cualquier usuario sin costo de gas.
     */
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }

    /**
     * @dev Función de vista pública para consultar el número total de depósitos realizados.
     * @return El número total de operaciones de depósito completadas.
     * @notice Esta función puede ser llamada por cualquier usuario sin costo de gas.
     */
    function getTotalDepositsCount() external view returns (uint256) {
        return depositCount;
    }

    /**
     * @dev Función de vista pública para consultar el número total de retiros realizados.
     * @return El número total de operaciones de retiro completadas.
     * @notice Esta función puede ser llamada por cualquier usuario sin costo de gas.
     */
    function getTotalWithdrawalsCount() external view returns (uint256) {
        return withdrawCount;
    }

    /**
     * @dev Función privada para verificar el saldo de un usuario.
     * @param account Dirección del usuario a consultar.
     * @return El saldo actual del usuario en wei.
     * @notice Esta función es interna y solo puede ser llamada por otras funciones del contrato.
     */
    function _checkBalance(address account) private view returns (uint256) {
        return balances[account];
    }
}