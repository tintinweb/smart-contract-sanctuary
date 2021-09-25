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
 
 https://www.littledogecoin.com/
 https://twitter.com/LittleDogeCoin
 https://t.me/LittleDogecoin
 https://www.facebook.com/LittleDogecoin
 https://github.com/littledogecoin
 https://www.reddit.com/r/LittleDogeCoin/
**/

/**
 * Inflationary Token at 14 Million token per day or 
 * %0.014 new token per day on day 1
 * or 5.11% for the 1st year
 * 
 * Why inflationary?
 * Little Dogecoin is one of the native token of the biggest defi project, the      
 *      Decentralised Liquidity-Based Cross-Asset Multi-Station Payment Gateway
 * 
 * Daily minted token will be used mainly for ecosystem growth, reward and marketing and payment refund.
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
 *  Anti-Bot Mechanism.
*/
import './BEP20.sol';
contract LittleDogeCoin is BEP20() {
    using SafeMath for uint256;
    using Address for address;
    // destination of minted tokens;
    // use for project funding for ecosystem growth, rewards and marketing
    address public _mintAddress;
    // Admin addresses
    mapping(address => bool) private _adminAddress;
    // Addresses that are allowed to do transction when transfer is locked;
    mapping(address => bool) private _allowedAddress;
	// keep the last mint block timestamp
    uint256 public _lastMint;
    // reward smart contract, 
    address public _rewardContract;
    // current minting rate per seconds;
    uint256 public _mintingRate; // max is 162037037037 or //162.037037037 token per seconds
    // minimum mintable token before minting can be executed;
    uint256 public _minimumMintLimit;
    // Lock the transfer. Will be use only for special cases;
    bool public enableTransfer;
    bool public enableRewardBalanceSync;
    
    //events
    event TransferStateChange(address changedBy, bool enabled);
    event AddAllowedAddress(address owner, bool state, address by);
    event UpdateMintAddress(address newMintAddress);
    event AdminAddress(address admin, bool state);
    constructor() {
        _name = "Test Doge";
        _symbol = "TDOGE";
        _decimals = 9;
        _owner = _msgSender();
        setAdminAddress(_msgSender(), true);
        //default values
        _minimumMintLimit = 100000e9;
        enableTransfer = false;
        _mintingRate = 162037037037;//162.037037037 token per seconds fix
        mint(_msgSender(), 100000000000e9);//100B LilDOGE
        _allowedAddress[_msgSender()]=true;
        enableRewardBalanceSync=false;
    }
    
    // allows admin uses only
    modifier onlyAdmin(){
        require(_adminAddress[_msgSender()], "LittleDogeCoin: caller is not an admin");
        _;
    }
    
    // Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        super._mint(_to, _amount);
    }
    
    // address that should be allowed to transact during special transaction like adding liquidity.
    // for emergency purpose and also use to prevent trading bot from taking advantage during public sale.
    // this function does not emit event so that trading bot would be able to detect.
    function addAllowedAddress(address allowedAddress, bool state)public onlyAdmin{
        _allowedAddress[allowedAddress] = state;
        emit AddAllowedAddress(allowedAddress, state, _msgSender());
    }
    
    // disable transfer state. this option is for maintenance and emergency use only;
    function setTransferState(bool state)public onlyAdmin{
        enableTransfer = state;
        emit TransferStateChange(_msgSender(), state);
    }
    
    // toggle the auto-sync of reward balance to reward smart contract
    function setRewardBalanceSync(bool state) public onlyAdmin{
        enableRewardBalanceSync = state;
    }
    
    // overrides transfer function to meet LittleDoge controls
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(enableTransfer == true || _allowedAddress[sender] || _allowedAddress[recipient], "LittleDogeCoin:: transfer is not allowed");
        super._transfer(sender, recipient, amount);
        mintSupply();// as per tokenomics, this smart contract will mint supply
    }
    
    // toggle address as admin;
    function setAdminAddress(address adminAddress, bool state)public onlyOwner{
        _adminAddress[adminAddress] = state;
        emit AdminAddress(adminAddress, state);
    }
    
    // sets minted token wallet address;
    // use for project funding for ecosystem growth, rewards and marketing
    function setMintAddress(address mintAddress)public onlyOwner{
        _mintAddress = mintAddress;
        _adminAddress[mintAddress] = true;
        emit UpdateMintAddress(mintAddress);
    }
    
    // toggle reward smart contract address ;
    function setRewardContract(address rewardContract)public onlyOwner{
        _rewardContract = rewardContract;
        _adminAddress[rewardContract] = true;
    }
    
    // sets the minimum token to mint
    function setMinimumMintLimit(uint256 limit)public onlyAdmin{
        _minimumMintLimit = limit;
    }
    
    // start the minting
    // use for project funding for ecosystem growth, rewards and marketing
    function startMinting()public onlyOwner{
        require(_lastMint == 0,"LittleDogeCoin:: minting already started");
        _lastMint = block.timestamp;
    }
    
    // mint tokens for rewards, marketing and ecosystem growth funding;
    // allow custom rewarding smart contract to transfer fund when claiming rewards
    function mintSupply() public{
        if(_lastMint > 0){
            uint256 amountToMint = block.timestamp.sub(_lastMint).mul(_mintingRate);
            if(amountToMint > _minimumMintLimit && _mintAddress != address(0)) {
                mint(_mintAddress, amountToMint);
                _lastMint = block.timestamp;
                if(_rewardContract != address(0) && enableRewardBalanceSync){
                    super._approve(_mintAddress, _rewardContract, balanceOf(_mintAddress));
                }
            }
        }
    }
    
    // allow the owner to recover other token accidentally sent to smart contract.
    function recoverBEP20(address tokenAddress, address sendTo, uint256 tokenAmount) public onlyOwner {
        require(tokenAddress != address(this), "LittleDogeCoin:: you are now allowed to recover LilDOGE token");
        IBEP20(tokenAddress).transfer(sendTo, tokenAmount);
    }
}