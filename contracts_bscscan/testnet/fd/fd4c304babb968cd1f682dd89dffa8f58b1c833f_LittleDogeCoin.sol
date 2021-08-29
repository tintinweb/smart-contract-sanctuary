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
 * Little Dogecoin is one of the native token of the biggest defi project, the CoreProtocol.finance.
 * 
 * CoreProtocol is a Patented Decentralized Cross-Chain Payment solution, Swap, Farming, Pools, Lottery, Lending, NFT.
 * Daily minted token will be used mainly for reward and marketing and payment refund.
 *
 * Feature:
 *  Zero tax, with lowest gas fee for fair trading.
 *  Automated Minting
 *  Anti-Bot Mechanism
 *  No Anti-Whale because only paperhands and shit project hates hates whales.
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
    // reward contract
    address public _rewardContract;
    // current minting rate per block;
    uint256 public _mintingRate;
    // current burning per transcation;
    uint256 public _minimumMintLimit;
    // Lock the trasfer. Will be use only for special cases;
    bool public enableTransfer;
    
    event TransferStateChange(address changedBy, bool enabled);
    event MintingRateChange(address changedBy, uint256 rate);
    
    constructor() {
        require(_totalSupply ==0,"LittleDoge:: already initialized");
        _name = "LittleDogecoin";
        _symbol = "LilDOGE";
        _decimals = 9;
        _owner = _msgSender();
        setAdminAddress(_msgSender(), true);
        //default values
        _minimumMintLimit = 10000e9;
        enableTransfer = false;
        _mintingRate = 1209600000000;//1209.6 token per seconds
        mint(_msgSender(), 100000000000e9);
        _allowedAddress[_msgSender()]=true;
    }
    
    // allows admin uses only
    modifier onlyAdmin(){
        require(_adminAddress[_msgSender()], "LittleDoge: caller is not an admin");
        _;
    }
    
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
    // address that should be allowed to transact during special transaction like adding liquidity.
    // also use to prevent trading bot. this function does not emit event so that trading bot.
    function addUnrestrictedAddress(address allowedAddress, bool state)public onlyAdmin{
        _allowedAddress[allowedAddress] = state;
    }
    
    // disable transfer state. this option is for maintenance and emergency use only;
    function setTransferState(bool state)public onlyAdmin{
        enableTransfer = state;
        emit TransferStateChange(_msgSender(), state);
    }
    // @dev overrides transfer function to meet LittleDoge controls
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(enableTransfer==true || _allowedAddress[sender] || _allowedAddress[recipient],"LittleDogeCoin:: transfer is not allowed");
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
        _mintingRate = mintingRate;
        emit MintingRateChange(_msgSender(), mintingRate);
    }
    // sets the minimum token to mint
    function setMinimumMintLimit(uint256 limit)public onlyAdmin{
        _minimumMintLimit = limit;
    }
    // start the minting
    function startMinting()public onlyAdmin{
        _lastMint = block.number;
    }
    // mint reward tokens for miners and promotions;
    function mintRewards() public{
        if(_lastMint > 0){
            uint256 amountToMint = block.number.sub(_lastMint).mul(_mintingRate);
            if(amountToMint > _minimumMintLimit && _mintAddress != address(0)) {
                _mint(_mintAddress, amountToMint);
                _lastMint = block.number;
                if(_rewardContract!=address(0)){
                    _approve(_mintAddress, _rewardContract, balanceOf(_mintAddress));
                }
            }
        }
    }
}