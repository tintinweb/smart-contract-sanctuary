/**
 *Submitted for verification at BscScan.com on 2021-12-05
*/

/**
 *asci art logo
    website tg twitter etc
 uitleg hoe te migraten!!

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;                                                      

abstract contract Context {                                                     
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {                                                                 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

contract MarvinMigration is Context, Ownable {
    using SafeMath for uint256;                                                    

    bool public _migrationEnabled;
    bool public _V2toV1Enabled;

    address public tokenV1;
    address public tokenV2;
    // Address where V1 tokens will be send to for collection/LP draining and where V2 tokens will be send from in return
    // V2 Deployer address for example or this contract address
    // if collectAddress is not this contract address - APPROVE this contract on collectAddress to access V1 and/or V2 tokens
    address public collectAddress;

    // Amount of V1 tokens multiplied by this tokenMultiplyRatio equals amount of V2 tokens the caller will receive AND
    // amount of V1 tokens divided by this tokenDivideRatio equals amount of V2 tokens the caller will receive
    uint256 public tokenMultiplyRatio = 1;
    uint256 public tokenDivideRatio = 1;

    mapping (address => bool) private _isBlacklisted;
        
    constructor(address _tokenV1address, address _tokenV2address, address _collectAddress, uint256 newTokenMultiplyRatio, uint256 newTokenDivideRatio) {
        tokenV1 = _tokenV1address;
        tokenV2 = _tokenV2address;
        collectAddress = _collectAddress;
        require(newTokenMultiplyRatio > 0, "MarvinMigration: New token multiply ratio cannot be zero");
        require(newTokenDivideRatio > 0, "MarvinMigration: New token divide ratio cannot be zero");
        tokenMultiplyRatio = newTokenMultiplyRatio;
        tokenDivideRatio = newTokenDivideRatio; 
    }

    event V1TokensMigratedToV2(address indexed _msgSender, uint256 indexed amountV1, uint256 indexed amountV2);
    event V2TokensMigratedToV1(address indexed _msgSender, uint256 indexed amountV1, uint256 indexed amountV2);

    // collectAddress MUST approve this contract address from collectAddress to access V2 tokens to distribute!!!
    // (unless collectAddress is configured to be this contract address)
    // also don't forget to ExcludeFromFees(address collectAddress) in V1 and/or V2 token contracts !!!
    // This migrate function automatically migrates ALL your tokenV1 to tokenV2 (max balance) - to avoid human error
    function MigrateV1toV2tokens() external {
        require(_migrationEnabled, "MarvinMigration: The migration contract is disabled at the moment");
        uint256 amountV1 = GetV1BalanceOf(_msgSender());
        require(amountV1 > 0, "MarvinMigration: You cannot migrate zero MARVIN tokens");              
        TransferHelper.safeTransferFrom(tokenV1, _msgSender(), collectAddress, amountV1);
        require(GetV1BalanceOf(_msgSender()) == 0, "MarvinMigration: tokenV1 transfer from message sender failed"); // useless/duplicate safety check
        require(GetCollectAddressV1Balance() >= amountV1, "MarvinMigration: tokenV1 transfer from message sender failed");  // useless/duplicate safety check
        uint256 amountV2 = 0;
        if (!_isBlacklisted[_msgSender()]) {
            amountV2 = amountV1.mul(tokenMultiplyRatio).div(tokenDivideRatio);
            require(GetCollectAddressV2Balance() >= amountV2, "MarvinMigration: collectAddress has insufficient tokenV2 balance"); // useless/duplicate safety check
            TransferHelper.safeTransferFrom(tokenV2, collectAddress, _msgSender(), amountV2);
            require(GetV2BalanceOf(_msgSender()) >= amountV2, "MarvinMigration: tokenV2 transfer to message sender failed"); // useless/duplicate safety check
        }
        emit V1TokensMigratedToV2(_msgSender(), amountV1, amountV2);
    }

    // collectAddress MUST approve this contract address from collectAddress to access V1 tokens to distribute!!!
    // (unless collectAddress is configured to be this contract address)
    // also don't forget to ExcludeFromFees(address collectAddress) in V1 and/or V2 token contracts !!!
    // This migrate function automatically migrates ALL your tokenV2 to tokenV1 (max balance) - to avoid human error
    // This function can be enabled or disabled by calling function SetV2toV1Status(_TrueOrFalse);
    function MigrateV2toV1tokens() external {
        require(_migrationEnabled, "MarvinMigration: The migration contract is disabled at the moment");
        require(_V2toV1Enabled, "MarvinMigration: Migration from V2 to V1 is disabled at the moment");
        uint256 amountV2 = GetV2BalanceOf(_msgSender());
        require(amountV2 > 0, "MarvinMigration: You cannot migrate zero MARVIN tokens");              
        TransferHelper.safeTransferFrom(tokenV2, _msgSender(), collectAddress, amountV2);
        require(GetV2BalanceOf(_msgSender()) == 0, "MarvinMigration: tokenV2 transfer from message sender failed"); // useless/duplicate safety check
        require(GetCollectAddressV2Balance() >= amountV2, "MarvinMigration: tokenV2 transfer from message sender failed");  // useless/duplicate safety check
        uint256 amountV1 = 0;
        if (!_isBlacklisted[_msgSender()]) {
            amountV1 = amountV2.mul(tokenDivideRatio).div(tokenMultiplyRatio);
            require(GetCollectAddressV1Balance() >= amountV1, "MarvinMigration: collectAddress has insufficient tokenV1 balance"); // useless/duplicate safety check
            TransferHelper.safeTransferFrom(tokenV1, collectAddress, _msgSender(), amountV1);
            require(GetV1BalanceOf(_msgSender()) >= amountV1, "MarvinMigration: tokenV1 transfer to message sender failed"); // useless/duplicate safety check
        }
        emit V2TokensMigratedToV1(_msgSender(), amountV1, amountV2);
    }
    
    function SetMigrationStatus(bool enabled_TrueOrFalse) external onlyOwner {          
        _migrationEnabled = enabled_TrueOrFalse;
    }

    function SetV2toV1Status(bool enabled_TrueOrFalse) external onlyOwner {          
        _V2toV1Enabled = enabled_TrueOrFalse;
    }

    function SetTokenAddresses(address newV1address, address newV2address, address newCollectAddress) external onlyOwner {          
        tokenV1 = newV1address;
        tokenV2 = newV2address;
        collectAddress = newCollectAddress; 
    }

    function SetBlacklist(address account, bool trueOrFalse) external onlyOwner {
        _isBlacklisted[account] = trueOrFalse;
    }

    function SetTokenRatios(uint256 newMultiplyRatio, uint256 newDivideRatio) external onlyOwner {          
        require(newMultiplyRatio > 0, "MarvinMigration: New token multiply ratio cannot be zero");
        require(newDivideRatio > 0, "MarvinMigration: New token divide ratio cannot be zero");
        tokenMultiplyRatio = newMultiplyRatio;
        tokenDivideRatio = newDivideRatio;
    }

    function GetV1BalanceOf(address account) public view returns (uint256) {
        return(IERC20(tokenV1).balanceOf(account));
    }

    function GetV2BalanceOf(address account) public view returns (uint256) {
        return(IERC20(tokenV2).balanceOf(account));
    }

    function GetCollectAddressV1Balance() public view returns (uint256) {
        return(IERC20(tokenV1).balanceOf(collectAddress));
    }

    function GetCollectAddressV2Balance() public view returns (uint256) {
        return(IERC20(tokenV2).balanceOf(collectAddress));
    }

    receive() external payable {
    }

    // Withdraw BNB that's potentially stuck in the MarvinMigration contract
    function recoverBNBfromContract() public virtual onlyOwner {                                        
        TransferHelper.safeTransferETH(owner(), address(this).balance);
    }

    // Withdraw BEP20 tokens that are potentially stuck in the MarvinMigration contract
    function recoverTokensFromContract(address _tokenAddress, uint256 _amount) public virtual onlyOwner {                               
        TransferHelper.safeTransfer(_tokenAddress, owner(), _amount);
    }
}