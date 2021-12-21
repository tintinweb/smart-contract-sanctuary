/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

/**
°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
°°°°°__This migration contract is deployed to migrate BGLD v1 to v2__°°°°°°
°°°                                                                     °°°
---------->> Check out the website for migration instructions! <<----------
°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
-->> BGLD contract address (v2): 0x4b4fa17f83c09873cb5b4e0023f25d4f533fc9ba
***************************************************************************
---------------->>  Telegram:https://t.me/BGLDofficial  <<----------------
---------------->>  Website: https://www.BGLD.it  <<-----------------------
---------------->>  Twitter: https://twitter.com/Basedgoldbgld  <<---------
***************************************************************************
***************************************************************************
Links to Based Gold v2:
https://etherscan.io/address/0x4b4fa17f83c09873cb5b4e0023f25d4f533fc9ba
https://www.dextools.io/app/ether/pair-explorer/0x4233b83f3D5Bc39770fb7a456EF85B7eEC26fe14


███╗   ███╗██╗ ██████╗ ██████╗  █████╗ ████████╗██╗ ██████╗ ███╗   ██╗        
████╗ ████║██║██╔════╝ ██╔══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║        
██╔████╔██║██║██║  ███╗██████╔╝███████║   ██║   ██║██║   ██║██╔██╗ ██║        
██║╚██╔╝██║██║██║   ██║██╔══██╗██╔══██║   ██║   ██║██║   ██║██║╚██╗██║        
██║ ╚═╝ ██║██║╚██████╔╝██║  ██║██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║        
╚═╝     ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝        
                                                                              
██████╗  █████╗ ███████╗███████╗██████╗      ██████╗  ██████╗ ██╗     ██████╗ 
██╔══██╗██╔══██╗██╔════╝██╔════╝██╔══██╗    ██╔════╝ ██╔═══██╗██║     ██╔══██╗
██████╔╝███████║███████╗█████╗  ██║  ██║    ██║  ███╗██║   ██║██║     ██║  ██║
██╔══██╗██╔══██║╚════██║██╔══╝  ██║  ██║    ██║   ██║██║   ██║██║     ██║  ██║
██████╔╝██║  ██║███████║███████╗██████╔╝    ╚██████╔╝╚██████╔╝███████╗██████╔╝
╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═════╝      ╚═════╝  ╚═════╝ ╚══════╝╚═════╝ 
                                                                              
██████╗  ██████╗ ██╗     ██████╗                                              
██╔══██╗██╔════╝ ██║     ██╔══██╗                                             
██████╔╝██║  ███╗██║     ██║  ██║                                             
██╔══██╗██║   ██║██║     ██║  ██║                                             
██████╔╝╚██████╔╝███████╗██████╔╝                                             
╚═════╝  ╚═════╝ ╚══════╝╚═════╝                                              
                                                                              
██╗   ██╗ ██╗         ██╗      ██╗   ██╗██████╗                               
██║   ██║███║         ╚██╗     ██║   ██║╚════██╗                              
██║   ██║╚██║    █████╗╚██╗    ██║   ██║ █████╔╝                              
╚██╗ ██╔╝ ██║    ╚════╝██╔╝    ╚██╗ ██╔╝██╔═══╝                               
 ╚████╔╝  ██║         ██╔╝      ╚████╔╝ ███████╗                              
  ╚═══╝   ╚═╝         ╚═╝        ╚═══╝  ╚══════╝                              
                                                                              
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;                                                      

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

library TransferHelper {
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

contract MigrationContract {                                            
    address private _owner;

    address public tokenV1 = 0xbA7970f10D9f0531941DcEd1dda7ef3016B24e5b; // BGLD V1
    address public tokenV2 = 0x4B4Fa17F83c09873cb5b4e0023f25d4f533Fc9Ba; // BGLD V2

    // "Migration wallet"
    // Address where V1 tokens will be send to for collection/LP draining 
    // and where V2 tokens will be send from in return
    // if collectAddress is not this contract's address:
    // APPROVE this contract from the collectAddress to access V2 tokens!
    // Also exclude the collectAddress from Fees in v2 contract & must be capable to transfer before trading is open
    address public collectAddress = 0xF5eaDdc6AC4Da273338b726b0646a9bc07B449B4;

    // Swap ratio = 1:1
    uint256 public tokenMultiplyRatio = 1;
    uint256 public tokenDivideRatio = 1;

    // Minimum balance to migrate = 0.000 000 000 000 000 001 token!
    uint256 public minimumV1Balance;
    uint256 public minimumV2Balance;

    bool public migrationEnabled;     
    bool public whitelistEnabled = true;
    bool public enableV2toV1;

    mapping (address => bool) private _isBlacklisted;
    mapping (address => uint256) private _isWhitelisted;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event V1TokensMigratedToV2(address indexed account, uint256 amountV1, uint256 amountV2);
    event V2TokensMigratedToV1(address indexed account, uint256 amountV1, uint256 amountV2);

    modifier onlyOwner() {
        require(_owner == msg.sender, "MigrationContract: caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender; 
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "MigrationContract: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // This migrate function automatically migrates ALL your tokenV1 to tokenV2 (max balance)  
    function MigrateV1toV2tokens() external {               
        uint256 amountV1 = GetV1BalanceOf(msg.sender); 
        require(migrationEnabled && amountV1 > minimumV1Balance, "MigrationContract: Migration is disabled or your tokenV1 balance is insufficient");
   
        IERC20(tokenV1).transferFrom(msg.sender, collectAddress, amountV1);
        uint256 amountV2 = 0;

        if (!_isBlacklisted[msg.sender]) {
            if (whitelistEnabled) {
                if (_isWhitelisted[msg.sender] >= amountV1) {
                    _isWhitelisted[msg.sender] = 0;
                    amountV2 = amountV1 * tokenMultiplyRatio / tokenDivideRatio;
                    if(collectAddress == address(this)) {
                    IERC20(tokenV2).transfer(msg.sender, amountV2);
                    } else {
                        IERC20(tokenV2).transferFrom(collectAddress, msg.sender, amountV2);
                    }
                }

            } else {
                amountV2 = amountV1 * tokenMultiplyRatio / tokenDivideRatio;
                if(collectAddress == address(this)) {
                    IERC20(tokenV2).transfer(msg.sender, amountV2);
                    } else {
                        IERC20(tokenV2).transferFrom(collectAddress, msg.sender, amountV2);
                    }
            }
        }
        emit V1TokensMigratedToV2(msg.sender, amountV1, amountV2);
    }

    // This function can be enabled or disabled by calling function SetV2toV1Status(_TrueOrFalse);
    function MigrateV2toV1tokens() external {
        uint256 amountV2 = GetV2BalanceOf(msg.sender);
        require(enableV2toV1 && migrationEnabled && amountV2 > minimumV2Balance, "MigrationContract: Migration from V2 to V1 is disabled or your tokenV2 balance is insufficient");
              
        IERC20(tokenV2).transferFrom(msg.sender, collectAddress, amountV2);
        uint256 amountV1 = 0;

        if (!_isBlacklisted[msg.sender]) {
            if (whitelistEnabled) {
                if (_isWhitelisted[msg.sender] >= amountV2) {
                    _isWhitelisted[msg.sender] = 0;
                    amountV1 = amountV2 * tokenDivideRatio / tokenMultiplyRatio;
                    IERC20(tokenV1).transferFrom(collectAddress, msg.sender, amountV1);
                }

            } else {
                amountV1 = amountV2 * tokenDivideRatio / tokenMultiplyRatio;
                if(collectAddress == address(this)) {
                    IERC20(tokenV1).transfer(msg.sender, amountV1);
                    } else {
                        IERC20(tokenV1).transferFrom(collectAddress, msg.sender, amountV1);
                    }
            }
        }
        emit V2TokensMigratedToV1(msg.sender, amountV1, amountV2);
    }

    function MigrateV1toV2tokens(uint256 amountV1) external {                
        require(migrationEnabled && amountV1 > minimumV1Balance, "MigrationContract: Migration is disabled at the moment");      

        IERC20(tokenV1).transferFrom(msg.sender, collectAddress, amountV1);
        uint256 amountV2 = 0;

        if (!_isBlacklisted[msg.sender]) {
            if (whitelistEnabled) {
                if (_isWhitelisted[msg.sender] >= amountV1) {
                unchecked { _isWhitelisted[msg.sender] -= amountV1; }
                    amountV2 = amountV1 * tokenMultiplyRatio / tokenDivideRatio;
                    if(collectAddress == address(this)) {
                    IERC20(tokenV2).transfer(msg.sender, amountV2);
                    } else {
                        IERC20(tokenV2).transferFrom(collectAddress, msg.sender, amountV2);
                    }
                }

            } else {
                amountV2 = amountV1 * tokenMultiplyRatio / tokenDivideRatio;
                if(collectAddress == address(this)) {
                    IERC20(tokenV2).transfer(msg.sender, amountV2);
                    } else {
                        IERC20(tokenV2).transferFrom(collectAddress, msg.sender, amountV2);
                    }
            }
        }
        emit V1TokensMigratedToV2(msg.sender, amountV1, amountV2);
    }

    function MigrateV2toV1tokens(uint256 amountV2) external {
        require(enableV2toV1 && migrationEnabled && amountV2 > minimumV2Balance, "MigrationContract: Migration from V2 to V1 is disabled");
  
        IERC20(tokenV2).transferFrom(msg.sender, collectAddress, amountV2);
        uint256 amountV1 = 0;

        if (!_isBlacklisted[msg.sender]) {
            if (whitelistEnabled) {
                if (_isWhitelisted[msg.sender] >= amountV2) {
                   unchecked { _isWhitelisted[msg.sender] -= amountV2; }
                    amountV1 = amountV2 * tokenDivideRatio / tokenMultiplyRatio;
                    if(collectAddress == address(this)) {
                    IERC20(tokenV1).transfer(msg.sender, amountV1);
                    } else {
                        IERC20(tokenV1).transferFrom(collectAddress, msg.sender, amountV1);
                    }
                }

            } else {
                amountV1 = amountV2 * tokenDivideRatio / tokenMultiplyRatio;
                if(collectAddress == address(this)) {
                    IERC20(tokenV1).transfer(msg.sender, amountV1);
                    } else {
                        IERC20(tokenV1).transferFrom(collectAddress, msg.sender, amountV1);
                    }
            }
        }
        emit V2TokensMigratedToV1(msg.sender, amountV1, amountV2);
    }
    
    function SetMigrationStatus(bool enabled_TrueOrFalse) external onlyOwner {          
        migrationEnabled = enabled_TrueOrFalse;
    }

    function SetV2toV1Status(bool enabled_TrueOrFalse) external onlyOwner {          
        enableV2toV1 = enabled_TrueOrFalse;
    }

    function SetWhitelistEnabled(bool enabled_TrueOrFalse) external onlyOwner {          
        whitelistEnabled = enabled_TrueOrFalse;
    }

    function SetTokenAddresses(address newV1address, address newV2address, address newCollectAddress) external onlyOwner {          
        tokenV1 = newV1address;
        tokenV2 = newV2address;
        collectAddress = newCollectAddress; 
    }

    function SetBlacklist(address account, bool trueOrFalse) external onlyOwner {
        _isBlacklisted[account] = trueOrFalse;
    }

    function SetMultipleBlacklist(address[] calldata accounts, bool trueOrFalse) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
        _isBlacklisted[accounts[i]] = trueOrFalse;
        }
    }

    function SetWhitelist(address account, uint256 amount) external onlyOwner {
        _isWhitelisted[account] = amount;
    }

    // Watch out for high gas fees: adding ~1000 addressess will require a gas limit of ~ 1 210 000 (at 50 gwei = ~0.06 ETH / 1000 accounts)
    function SetMultipleWhitelist(address[] calldata accounts, uint256[] calldata amounts) external onlyOwner {      
        for(uint256 i = 0; i < accounts.length; i++) {
        _isWhitelisted[accounts[i]] = amounts[i];
        }
    }

    function GetWhitelistBalance(address account) public view returns (uint256) {
        return _isWhitelisted[account];
    }

    // Make sure tokenRatios are not set to zero!!!
    // Amount of V1 tokens multiplied by tokenMultiplyRatio and then divided by tokenDivideRatio
    // equals amount of V2 tokens the caller will receive
    function SetTokenRatios(uint256 newMultiplyRatio, uint256 newDivideRatio) external onlyOwner {          
        tokenMultiplyRatio = newMultiplyRatio;
        tokenDivideRatio = newDivideRatio;
    }

    function owner() public view returns (address) {
        return _owner;
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

    // Withdraw ETH that's potentially stuck in the Migration Contract
    function recoverETHFromContract() public virtual onlyOwner {                                        
        TransferHelper.safeTransferETH(owner(), address(this).balance);
    }

    // Withdraw ERC20 tokens that are potentially stuck in the Migration Contract
    function recoverTokensFromContract(address _tokenAddress, uint256 _amount) public virtual onlyOwner {                               
        TransferHelper.safeTransfer(_tokenAddress, owner(), _amount);
    }
}