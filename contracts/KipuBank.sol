// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title KipuBank
 * @dev A simple bank contract that allows users to deposit and withdraw ETH with certain restrictions.
 * @notice This contract demonstrates basic Solidity concepts and security best practices.
 */
contract KipuBank {
    /**
     * @notice State variables that store information about the bank
     */
    
    /// @notice Version of the KipuBank contract
    string public constant VERSION = "1.0.0";
    
    // State variables
    /// @notice Total number of deposit operations performed
    uint256 private depositCount;
    
    /// @notice Total number of withdrawal operations performed
    uint256 private withdrawCount;
    
    /// @notice Maximum amount that can be withdrawn in a single transaction
    uint256 private immutable withdrawLimit;
    
    /// @notice Total limit of ETH that can be deposited in the bank
    uint256 private immutable bankCap;
    
    /// @notice Total sum of ETH currently deposited in the bank
    uint256 private totalDeposits;
    
    /// @notice Mapping of addresses to their deposited balances
    mapping(address => uint256) public balances;
    
    /// @notice Address of the contract owner
    address private immutable owner;
    
    /// @notice Variable to prevent reentrancy attacks
    bool private locked;
    
    // Events
    /// @notice Emitted when a user makes a deposit
    /// @param account Address of the user making the deposit
    /// @param amount Amount of ETH deposited
    event Deposit(address indexed account, uint256 amount);
    
    /// @notice Emitted when a user makes a withdrawal
    /// @param account Address of the user making the withdrawal
    /// @param amount Amount of ETH withdrawn
    event Withdraw(address indexed account, uint256 amount);
    
    // Custom errors
    /// @notice Error thrown when a deposit exceeds the bank's capacity
    /// @param attempted Amount attempted to deposit
    /// @param available Available space in the bank
    error ExceedsBankCap(uint256 attempted, uint256 available);
    
    /// @notice Error thrown when a withdrawal exceeds the per-transaction limit
    /// @param attempted Amount attempted to withdraw
    /// @param limit Maximum withdrawal limit
    error ExceedsWithdrawLimit(uint256 attempted, uint256 limit);
    
    /// @notice Error thrown when a user tries to withdraw more than their balance
    /// @param available User's available balance
    /// @param required Amount requested for withdrawal
    error InsufficientBalance(uint256 available, uint256 required);
    
    /// @notice Error thrown when an ETH transfer fails
    error TransferFailed();
    
    /// @notice Error thrown when a reentrancy attempt is detected
    error ReentrancyDetected();
    
    /// @notice Error thrown when the withdrawal limit in constructor is invalid
    error InvalidWithdrawLimit();
    
    /// @notice Error thrown when the bank capacity in constructor is invalid
    error InvalidBankCap();
    
    // Modifier to prevent reentrancy
    /// @notice Modifier that prevents reentrancy attacks
    modifier noReentrancy() {
        if (locked) {
            revert ReentrancyDetected();
        }
        locked = true;
        _;
        locked = false;
    }
    


    /**
     * @dev Constructor that sets the limits and owner of the contract.
     * @param _withdrawLimit Withdrawal limit per transaction in wei.
     * @param _bankCap Global deposit limit in wei.
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
     * @dev Allows users to deposit ETH into their personal vault.
     * @notice Requires that the deposit does not exceed the global bank limit.
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
     * @dev Allows users to withdraw ETH from their personal vault.
     * @notice Requires that the withdrawal does not exceed the per-transaction limit and that the user has sufficient balance.
     * @param amount Amount of ETH to withdraw in wei.
     * @custom:security Protected against reentrancy and overflows
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
     * @dev Public view function to query the bank's total balance.
     * @return The total balance of ETH currently deposited in the bank.
     * @notice This function can be called by any user without gas cost.
     */
    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }

    /**
     * @dev Public view function to query the total number of deposits made.
     * @return The total number of completed deposit operations.
     * @notice This function can be called by any user without gas cost.
     */
    function getTotalDepositsCount() external view returns (uint256) {
        return depositCount;
    }

    /**
     * @dev Public view function to query the total number of withdrawals made.
     * @return The total number of completed withdrawal operations.
     * @notice This function can be called by any user without gas cost.
     */
    function getTotalWithdrawalsCount() external view returns (uint256) {
        return withdrawCount;
    }

    /**
     * @dev Private function to check a user's balance.
     * @param account Address of the user to query.
     * @return The user's current balance in wei.
     * @notice This function is internal and can only be called by other contract functions.
     */
    function _checkBalance(address account) private view returns (uint256) {
        return balances[account];
    }
}