/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: No License (None)
pragma solidity ^0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/ownership/Ownable.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Ownable implementation from an openzeppelin version.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(),"Not Owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0),"Zero address not allowed");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IGatewayVault {
    function vaultTransfer(address token, address recipient, uint256 amount) external returns (bool);
    function vaultApprove(address token, address spender, uint256 amount) external returns (bool);
}

interface IDegen {
    enum OrderType {EthForTokens, TokensForEth, TokensForTokens}
    function callbackCrossExchange(uint256 orderType, address[] memory path, uint256 assetInOffered, address user, uint256 dexId, uint256 deadline)
    external returns(bool);
    function callbackCrossExchange1Inch(
        address fromToken,  // swap from token
        uint256 amount,     // token amount
        address to,         // 1Inch router. Form API response.
        bytes memory data   // Form 1Inch API response.
    ) external returns(bool);
}

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
}

contract DegenBridge is Ownable {
    using TransferHelper for address;
    
    address public USDT = address(0);

    uint256 _nonce = 0;
    mapping(uint256 => bool) public nonceProcessed;
    
    address public system;  // system address may change fee amount
    bool public paused;
    address public gatewayVault; // GatewayVault contract
    address public degenContract;
    
    event SwapRequest(
        address indexed tokenA, 
        address indexed tokenB, 
        address indexed user, 
        uint256 amount,
        uint256 crossOrderType,
        uint256 nonce,
        uint256 dexId,
        uint256 deadline
    );

    // event ClaimRequest(address indexed tokenA, address indexed tokenB, address indexed user, uint256 amount);
    event ClaimApprove(
        address indexed tokenA, 
        address indexed tokenB, 
        address indexed user, 
        uint256 amount, 
        uint256 crossOrderType,
        uint256 dexId,
        uint256 deadline
    );

    modifier notPaused() {
        require(!paused,"Swap paused");
        _;
    }

    /**
    * @dev Throws if called by any account other than the system.
    */
    modifier onlySystem() {
        require(msg.sender == system || owner() == msg.sender,"Caller is not the system");
        _;
    }

    constructor (address _system, address _gatewayVault, address _usdt) {
        system = _system;
        gatewayVault = _gatewayVault;
        USDT = _usdt;
    }


    function setDegenContract(address _degenContract) external onlyOwner returns(bool) {
        degenContract = _degenContract;
        return true;
    }

    function setGatewayVault(address _gatewayVault) external onlyOwner returns(bool) {
        gatewayVault = _gatewayVault;
        return true;
    }

    function setSystem(address _system) external onlyOwner returns(bool) {
        system = _system;
        return true;
    }
    
    function setUSDT(address _usdt) external onlyOwner returns(bool) {
        USDT = _usdt;
        return true;
    }
    
    function setPause(bool pause) external onlyOwner returns(bool) {
        paused = pause;
        return true;
    }

    function getTransactionStatus(uint256 nonce) external view returns (bool){
      return nonceProcessed[nonce];
    }

    //user should approve tokens transfer before calling this function.
    // for local swap (tokens on the same chain): pair = address(1) when TokenA = JNTR, and address(2) when TokenB = JNTR
    function swap(address tokenA, address tokenB, uint256 amount, address user, uint256 crossOrderType, uint256 dexId, uint256 deadline) 
    external payable notPaused returns (bool) {
        require(msg.sender == degenContract, "Only Degen");
        require(amount != 0, "Zero amount");
        require(gatewayVault != address(0), "No vault address");
        require(deadline >= block.timestamp, "EXPIRED: Deadline for bridge transaction already passed.");
        tokenA.safeTransferFrom(msg.sender, gatewayVault, amount);
        _nonce = _nonce+1;
        emit SwapRequest(tokenA, tokenB, user, amount, crossOrderType, _nonce, dexId, deadline);
        return true;
    }

    function claimTokenBehalf(address[] memory path, address user, uint256 amount, uint256 crossOrderType, uint256 nonce, uint256 dexId, uint256 deadline)
    external onlySystem notPaused returns (bool) {
        require(!nonceProcessed[nonce], "Exchange already processed");
        require(deadline >= block.timestamp, "EXPIRED: Deadline for claim transaction already passed.");
        nonceProcessed[nonce] = true;
        if(path[path.length-1] == USDT) {
            IGatewayVault(gatewayVault).vaultTransfer(USDT, user, amount); 
        } 
        else {
            uint256 orderType = 2; // TokensForTokens;
            if (crossOrderType & 1 != 0) orderType = 1; // TokensForEth;
            IGatewayVault(gatewayVault).vaultTransfer(USDT, degenContract, amount); 
            IDegen(degenContract).callbackCrossExchange(orderType, path, amount, user, dexId, deadline);
        }
        emit ClaimApprove(path[0], path[path.length-1], user, amount, crossOrderType, dexId, deadline);
        return true;
    }



    // when call `swap` API of 1Inch, you have to set:
    // `fromTokenAddress` - USDT token address
    // `toTokenAddress ` - token user want to receive
    // `amount` - amount of USDT tokens
    // `fromAddress` - GatewayVault contract address.
    // `slippage` - from user's setting
    // `destReceiver` - Degen contract address
    function claimTokenBehalf1Inch(
        address[] memory path,
        address to,         // 1Inch router. Form API response. Should be approved tp transfer USDT from Vault
        bytes memory data,  // Form 1Inch API response.
        address user,
        uint256 amount,
        uint256 crossOrderType,
        uint256 nonce,
        uint256 dexId,
        uint256 deadline
    )
        external 
        onlySystem 
        notPaused returns (bool) 
    {
        require(!nonceProcessed[nonce], "Exchange already processed");
        require(deadline >= block.timestamp, "EXPIRED: Deadline for claim transaction already passed.");
        nonceProcessed[nonce] = true;
        IGatewayVault(gatewayVault).vaultTransfer(USDT, address(this), amount);
        USDT.safeApprove(to, amount);
        //IDegen(degenContract).callbackCrossExchange1Inch(USDT, amount, to, data);
        (bool success,) = to.call{value: 0}(data);
        require(success, "call to contract error");
 
        emit ClaimApprove(path[0], path[path.length-1], user, amount, crossOrderType, dexId, deadline);
        return true;
    }

    // If someone accidentally transfer tokens to this contract, the owner will be able to rescue it and refund sender.
    function rescueTokens(address _token) external onlyOwner {
        if (address(0) == _token) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            uint256 available = IBEP20(_token).balanceOf(address(this));
            _token.safeTransfer(msg.sender, available);
        }
    }
}