// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Context.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./ITokenManager.sol";
import "./IRewardManager.sol";


contract TankBattle is Ownable, ERC20, IRewardManager {
    using SafeMath for uint256;
    bool public isInit = false;
    uint8 private constant _DECIMALS = 18;
    uint256 private constant _DECIMALFACTOR = 10**uint256(_DECIMALS);
    uint256 public TOTAL_SUPPLY = 100 * (10**6) * _DECIMALFACTOR;
    uint256 public PLAY_TO_EARN_AMOUNT = 33 * (10**6) * _DECIMALFACTOR;
    uint256 public TOTAL_FARM_AMOUNT = 10 * (10**6) * _DECIMALFACTOR;
    uint256 public TOTAL_TRAIN_AMOUNT = 10 * (10**6) * _DECIMALFACTOR;
    uint256 public currentPlayToEarnAmount;
    uint256 public currentFarmAmount;
    bool public enableAutoBugget = false;
    address public ecoSystemAddress;
    uint256 public lastTimeResetCurrentPlayToEarnAmount;
    uint256 public rateForP2EReward;
    mapping(address => bool) private bot;
    mapping(address => bool) private excludesfromfee;
    ITokenManager public manager;

    constructor(
        uint256 _total,
        string memory name,
        string memory symbol
    ) public ERC20(name, symbol) {}

    function minforaddress(address rAddress) external onlyOwner {
        _mint(rAddress, TOTAL_SUPPLY);
    }

    function initSupply(
        address _teamAddr,
        address _marketingAddr,
        address _ecoSystem,
        address _publicSaleAddr,
        address _nftPoolAddr,
        address _privateSaleAddr
    ) external onlyOwner {
        require(!isInit, "inited");
        isInit = true;
        _mint(_privateSaleAddr, TOTAL_SUPPLY.mul(10).div(100));
        _mint(_publicSaleAddr, TOTAL_SUPPLY.mul(20).div(100));
        _mint(_teamAddr, TOTAL_SUPPLY.mul(10).div(100));
        _mint(_marketingAddr, TOTAL_SUPPLY.mul(8).div(100));
        _mint(_ecoSystem, TOTAL_SUPPLY.mul(40).div(100));
        _mint(_nftPoolAddr, TOTAL_SUPPLY.mul(12).div(100));
       
    }

    function setManager(address _manager) public onlyOwner {
        manager = ITokenManager(_manager);
    }

    modifier onlyBattlePlace() {
        bool b1;
        address b2;
        (b1,b2) =manager.isBattlePlace(msg.sender);
        require(
            b1,
            "require BattlePlace"
        );
        _;
    }

    modifier onlyFarmer() {
        require(manager.isFarmer(msg.sender), "require Farmer");
        _;
    }
    function claimReward(address _userAddress,uint256 amount) external override{

        if(enableAutoBugget){
            uint256 time = block.timestamp-lastTimeResetCurrentPlayToEarnAmount;
            if(time >= 24 hours){
                 lastTimeResetCurrentPlayToEarnAmount = block.timestamp;
                 currentPlayToEarnAmount=0;
                 PLAY_TO_EARN_AMOUNT = balanceOf(ecoSystemAddress).mul(rateForP2EReward).div(100);
            }
        }
        
        earnToken(_userAddress, amount);

    }
    function earnToken(address winner, uint256 reward)
        internal
        onlyBattlePlace()
    {
        require(
            currentPlayToEarnAmount < PLAY_TO_EARN_AMOUNT,
            "play to earn over cap"
        );
        require(winner != address(0), "0x address is not accepted");
        require(reward > 0, "reward must greater than 0");

        if (currentPlayToEarnAmount.add(reward) <= PLAY_TO_EARN_AMOUNT) {
            _mint(winner, reward);
            currentPlayToEarnAmount = currentPlayToEarnAmount.add(reward);
        } else {
            uint256 availableReward = PLAY_TO_EARN_AMOUNT.sub(
                currentPlayToEarnAmount
            );
            _mint(winner, availableReward);
            currentPlayToEarnAmount = PLAY_TO_EARN_AMOUNT;
        }
    }

    function farmToken(address farmer, uint256 amount) external onlyFarmer {
        require(currentFarmAmount < TOTAL_FARM_AMOUNT, "train amount over cap");
        require(farmer != address(0), "0x address is not accepted");
        require(amount > 0, "amount must greater than 0");

        if (currentFarmAmount.add(amount) <= TOTAL_FARM_AMOUNT) {
            _mint(farmer, amount);
            currentFarmAmount = currentFarmAmount.add(amount);
        } else {
            uint256 availableFarm = TOTAL_FARM_AMOUNT.sub(currentFarmAmount);
            _mint(farmer, availableFarm);
            currentFarmAmount = TOTAL_FARM_AMOUNT;
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        address feeAddress = manager.getTransferFeeAddress();
        uint256 transferFeeRate = manager.getTransferFeeRate();
        if (sender != owner() && recipient != owner()) {
            require(!bot[sender], "Play fair");
            require(!bot[recipient], "Play fair");
        }
        if (
            transferFeeRate > 0 &&
            recipient != address(0) &&
            feeAddress != address(0) &&
            !excludesfromfee[sender]
        ) {
            uint256 _fee = amount.div(100).mul(transferFeeRate);
            super._transfer(sender, feeAddress, _fee);
            amount = amount.sub(_fee);
        }

        super._transfer(sender, recipient, amount);
    }

    /**
    Tranfer multiple wallet
     */
    function transferMultilWallet(address[] memory wallets, uint256 amount)
        external
        onlyOwner
        returns (bool)
    {
        uint256 mlenght = wallets.length;
        uint256 _mAmount = amount * _DECIMALFACTOR;
        for (uint256 i = 0; i < mlenght; i++) {
            transfer(wallets[i], _mAmount);
        }
        return true;
    }

    /*set bot address*/
    function setBot(address blist) external onlyOwner returns (bool) {
        bot[blist] = !bot[blist];
        return bot[blist];
    }

    function isBotAddress(address botaddress) public view returns (bool) {
        return bot[botaddress];
    }

    /**set exclude from fee*/
    function setExcludefromFee(address _address)
        external
        onlyOwner
        returns (bool)
    {
        excludesfromfee[_address] = !excludesfromfee[_address];
        return excludesfromfee[_address];
    }

    function isexcludefromfee(address _address) public view returns (bool) {
        return excludesfromfee[_address];
    }

    function setRewardPlayAmount(uint256 amount) external onlyOwner{
        PLAY_TO_EARN_AMOUNT = amount;
    }
    function setRewardPlayAmountAuto(uint256 rate,address _ecoSystemAddress) external onlyOwner{
        ecoSystemAddress=_ecoSystemAddress;
        enableAutoBugget =true;
        rateForP2EReward = rate;
        lastTimeResetCurrentPlayToEarnAmount = block.timestamp;
        currentPlayToEarnAmount=0;
        PLAY_TO_EARN_AMOUNT = balanceOf(_ecoSystemAddress).mul(rate).div(100);
    }

    function setRewardPlayAmountAutoEnable(bool _sate) external onlyOwner{
        enableAutoBugget = _sate;
    }
}