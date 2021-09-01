// SPDX-License-Identifier: No License
pragma solidity >=0.8.7;
/**
 #                                    ######                          #####                 
 #       # ##### ##### #      ######  #     #  ####   ####  ######   #     #  ####  # #    # 
 #       #   #     #   #      #       #     # #    # #    # #        #       #    # # ##   # 
 #       #   #     #   #      #####   #     # #    # #      #####    #       #    # # # #  # 
 #       #   #     #   #      #       #     # #    # #  ### #        #       #    # # #  # # 
 #       #   #     #   #      #       #     # #    # #    # #        #     # #    # # #   ## 
 ####### #   #     #   ###### ######  ######   ####   ####  ######    #####   ####  # #    #  
**/

/**
 * Inflationary Token at 14 Million token per day MAX or %0.014 new token per day at day 1
 * 
 * Why inflationary?
 * Little Dogecoin is one of the native token of the biggest defi project, the
 *      
 *      Decentralised Liquidity-Based Cross-Asset Multi-Station Payment Gateway
 *  
 * Daily minted token will be used mainly for reward and marketing and payment refund.
 * Project Features
 *  Payment with auto-convertion stable coin, such as USDT, BUSD, DAI, EUR, or any Token.
 *  Remittance transfer with customized DApp;
 *  Bank Transfer with customized DApp;
 *  Peer-To-Peer with customized DApp;
 *  DApp Store and Factories;
 *  Personalized DApp for fund automations;
 *  DEX, Farming, Pools, Lottery, Lending, NFT, etc.
 *
 * Token Feature:
 *  Zero tax, with lowest gas fee for fair trading.
 *  Automated Minting
 *  Anti-Bot Mechanism
 *  No Anti-Whale -only paperhands and shit project hates whales.
*/
import './BEP20.sol';
contract LittleDogeCoin is BEP20() {
    using SafeMath for uint256;
    using Address for address;
    // destination of minted tokens;
    address public _mintAddress;
    // Admin addresses
    mapping(address => bool) private _adminAddress;
    // Addresses that are allowed to do transction when transfer is locked;
    mapping(address => bool) private _allowedAddress;
	// keeps the last mint block timestamp
    uint256 public _lastMint;
    // reward smart contract, 
    address public _rewardContract;
    // current minting rate per block;
    uint256 public _mintingRate; // max is 1209600000000 or //1209.6 token per seconds
    // minimum mintable token before minting can be executed;
    uint256 public _minimumMintLimit;
    // Lock the transfer. Will be use only for special cases;
    bool public enableTransfer;
    bool public enableRewardContractBalanceSync;
    event TransferStateChange(address changedBy, bool enabled);
    event MintingRateChange(address changedBy, uint256 rate);
    
    constructor() {
        _name = "LittleDogecoin";
        _symbol = "DEMO1";
        _decimals = 9;
        _owner = _msgSender();
        setAdminAddress(_msgSender(), true);
        //default values
        _minimumMintLimit = 10000e9;
        enableTransfer = false;
        _mintingRate = 1209600000000;//1209.6 token per seconds
        mint(_msgSender(), 100000000000e9);
        _allowedAddress[_msgSender()]=true;
        enableRewardContractBalanceSync=false;
    }
    // allows admin uses only
    modifier onlyAdmin(){
        require(_adminAddress[_msgSender()], "LittleDogeCoin: caller is not an admin");
        _;
    }
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        super._mint(_to, _amount);
    }
    // address that should be allowed to transact during special transaction like adding liquidity.
    // for emergency purpose and also use to prevent trading bot from taking advantage during public sale.
    // this function does not emit event so that trading bot would be able to detect.
    function addAllowedAddress(address allowedAddress, bool state)public onlyAdmin{
        _allowedAddress[allowedAddress] = state;
    }
    // disable transfer state. this option is for maintenance and emergency use only;
    function setTransferState(bool state)public onlyAdmin{
        enableTransfer = state;
        emit TransferStateChange(_msgSender(), state);
    }
    // toggle the auto-sync of reward balance to reward smart contract
    function setRewardContractBalanceSync(bool state) public onlyAdmin{
        enableRewardContractBalanceSync = state;
    }
    // @dev overrides transfer function to meet LittleDoge controls
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(enableTransfer == true || _allowedAddress[sender] || _allowedAddress[recipient], "LittleDogeCoin:: transfer is not allowed");
        super._transfer(sender, recipient, amount);
        mintRewards();
    }
    // toggle address as admin;
    function setAdminAddress(address adminAddress, bool state)public onlyOwner{
        _adminAddress[adminAddress] = state;
    }
    // sets minted token wallet address;
    function setMintAddress(address mintAddress)public onlyOwner{
        _mintAddress = mintAddress;
        _adminAddress[mintAddress] = true;
    }
    // toggle reward smart contract address ;
    function setRewardContract(address rewardContract)public onlyOwner{
        _rewardContract = rewardContract;
        _adminAddress[rewardContract] = true;
    }
    // sets minting rate;
    function setMintingRate(uint256 mintingRate)public onlyAdmin{
        require(mintingRate <= 1209600000000,"LittleDogeCoin:: mintingRate too high");
        _mintingRate = mintingRate;
        emit MintingRateChange(_msgSender(), mintingRate);
    }
    // sets the minimum token to mint
    function setMinimumMintLimit(uint256 limit)public onlyAdmin{
        _minimumMintLimit = limit;
    }
    // start the minting
    function startMinting()public onlyAdmin{
        _lastMint = block.timestamp;
    }
    // mint reward tokens for marketing and promotions funding;
    function mintRewards() public{
        if(_lastMint > 0){
            uint256 amountToMint = block.timestamp.sub(_lastMint).mul(_mintingRate);
            if(amountToMint > _minimumMintLimit && _mintAddress != address(0)) {
                mint(_mintAddress, amountToMint);
                _lastMint = block.timestamp;
                if(_rewardContract != address(0) && enableRewardContractBalanceSync){
                    super._approve(_mintAddress, _rewardContract, balanceOf(_mintAddress));
                }
            }
        }
    }
}