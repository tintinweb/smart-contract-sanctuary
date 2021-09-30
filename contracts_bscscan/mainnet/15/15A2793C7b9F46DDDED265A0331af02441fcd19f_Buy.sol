/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

abstract contract IERC20 {
    function balanceOf(address _owner) public view virtual returns (uint256 balance);
    function transferFrom(address owner, address buyer, uint256 numTokens) public virtual returns (bool);
    function transfer(address buyer, uint256 numTokens) public virtual returns (bool);
}

abstract contract RandomNumberConsumer {
    function getRandomNumber() external virtual returns (bytes32 requestId);
    function getRandoms() external view virtual returns (uint256 _r1, uint256 _r2, uint256 _r3, uint256 _r4, uint256 _r5, uint256 _r6, uint256 _r7, uint256 _r8);
}

abstract contract ICT {
    function createToken(address _owner, string memory _name, string memory _class, string memory _syndicate, bool _isBoss,
                            string memory _genAttr, string memory _genElem, uint16 _potentialMax) public virtual returns (uint256);
    function levelUp(uint256 _fighter, uint8 _h, uint8 _a, uint8 _d, uint8 _s, uint8 _decPotentialMax) public virtual;
}

contract Buy {
    
    bool public paused = false;
    address public owner;
    address public newContractOwner;
    
    uint256 public bossPrice;
    uint256 public fighterPrice;
    address public nftAddress;
    address public paymentTokenAddress;
    address public rncAddress;
    address payable[] public distributionWallets;
    mapping(address => uint8) public walletPercentage;

    mapping (string => bool) public isBoss;
    mapping (string => string) classFor;
    mapping (string => string) syndicateFor;
    mapping (string => uint16) potentialMaxFor;
    mapping (string => mapping (string => uint8[])) public initialRanges;
 
    event Pause();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    event ClassRangesChanged(string class);
    event NewAvatar(string name, bool isBoss, uint16 potentialMax);
    
    string[] genAttr = ["Karate", "Taekwondo", "Muay Thai", "MMA", "Wrestling"];
    string[] elements = ["Fire", "Water", "Earth", "Wind", "Thunder"];
 
    constructor (address _nftAddress, uint256 _bossPrice, uint256 _fighterPrice) {
        owner = msg.sender;
        rncAddress = 0x5b214ac028a0c7cd9EBCAf34AF4C20eBEFdC59dD;
        
        bossPrice = _bossPrice;
        fighterPrice = _fighterPrice;
        nftAddress = _nftAddress;
    }
 
    modifier ifNotPaused {
        require(!paused);
        _;
    }
 
    modifier onlyContractOwner {
        require(msg.sender == owner);
        _;
    }
 
    function transferOwnership(address _newOwner) external onlyContractOwner {
        require(_newOwner != address(0));
        newContractOwner = _newOwner;
    }
 
    function acceptOwnership() external {
        require(msg.sender == newContractOwner);
        emit OwnershipTransferred(owner, newContractOwner);
        owner = newContractOwner;
        newContractOwner = address(0);
    }
 
    function setPause(bool _paused) external onlyContractOwner {
        paused = _paused;
        if (paused) {
            emit Pause();
        }
    }
    
    //////////// RANDOM AND ATTR GENERATING //////////////////
 
    function _seed(uint8 _nonce) private view returns (uint256 seed) {
        RandomNumberConsumer rnc = RandomNumberConsumer(rncAddress);
        (uint256 r1, uint256 r2, uint256 r3, uint256 r4, uint256 r5, uint256 r6, uint256 r7, uint256 r8) = rnc.getRandoms();
        if (_nonce == 1){
            return r1;
        } else if (_nonce == 2){
            return r2;
        } else if (_nonce == 3){
            return r3;
        } else if (_nonce == 4){
            return r4;
        } else if (_nonce == 5){
            return r5;
        } else if (_nonce == 6){
            return r6;
        } else if (_nonce == 7){
            return r7;
        } else if (_nonce == 8){
            return r8;
        }
    }
    
    function _random(uint8[] memory _range, uint8 _nonce) private view returns (uint8) {
        uint8 _min = _range[0];
        uint8 _max = _range[1];
        require(_max > _min);
        uint8 diff = _max - _min;
        return _min + uint8((_seed(_nonce) + _nonce) % (diff + 1));
    }
    
    function _random(uint8 _max, uint8 _nonce) private view returns (uint8) {
        return uint8((_seed(_nonce) + _nonce) % (_max + 1));
    }
    
    function addAvatar(string memory _name, bool _isBoss, string memory _class, string memory _syndicate, uint16 _potentialMax) public onlyContractOwner ifNotPaused {
        isBoss[_name] = _isBoss;
        classFor[_name] = _class;
        syndicateFor[_name] = _syndicate;
        potentialMaxFor[_name] = _potentialMax;
        
        emit NewAvatar(_name, _isBoss, _potentialMax);
    }
    
    function setRanges(string memory _rangeId, uint8 _hpMin, uint8 _hpMax, uint8 _attackMin, uint8 _attackMax,
        uint8 _defenseMin, uint8 _defenseMax, uint8 _agilityMin, uint8 _agilityMax) public onlyContractOwner ifNotPaused {
        initialRanges[_rangeId]["hp"] = [_hpMin, _hpMax];
        initialRanges[_rangeId]["attack"] = [_attackMin, _attackMax];
        initialRanges[_rangeId]["defense"] = [_defenseMin, _defenseMax];
        initialRanges[_rangeId]["agility"] = [_agilityMin, _agilityMax];
        
        emit ClassRangesChanged(_rangeId);
    }
    
    ////////////////// BUY CONTRACT ////////////////////
 
    function setPrices(uint256 _fighterPrice, uint256 _bossPrice) external onlyContractOwner {
        fighterPrice = _fighterPrice;
        bossPrice = _bossPrice;
    }
    
    function setPaymentToken(address _tokenAddress) external onlyContractOwner {
        paymentTokenAddress = _tokenAddress;
    }
    
    function setNFTAddress(address _nftAddress) external onlyContractOwner {
        nftAddress = _nftAddress;
    }
    
    function setRandomGenerator(address _generatorAddress) external onlyContractOwner {
        rncAddress = _generatorAddress;
    }
 
    function addWallet(uint8 _percentage, address payable _wallet) external onlyContractOwner {
        distributionWallets.push(_wallet);
        walletPercentage[_wallet] = _percentage;
    }
 
    function getWallet(uint8 _index) external view onlyContractOwner returns (address _wallet, uint8 _percentage) {
        _wallet = distributionWallets[_index];
        _percentage = walletPercentage[_wallet];
    }
 
    function removeWallet(uint8 _index) external onlyContractOwner {
        address wallet = address(distributionWallets[_index]);
        delete distributionWallets[_index];
        delete walletPercentage[wallet];
    }
    
    function _firstLevelUp(uint256 _newFighterId, string memory _name) internal {
        ICT nft = ICT(nftAddress);
        string memory class = classFor[_name];
        string memory syndicate = syndicateFor[_name];
        string memory rangeId = isBoss[_name] ? syndicate : class;
        uint8 _hp = _random(initialRanges[rangeId]["hp"], 0);
        uint8 _attack = _random(initialRanges[rangeId]["attack"], 1);
        uint8 _defense = _random(initialRanges[rangeId]["defense"], 2);
        uint8 _agility = _random(initialRanges[rangeId]["agility"], 3);
        nft.levelUp(_newFighterId, _hp, _attack, _defense, _agility, 0);
    }
 
    function buyFighter(string memory _name) external ifNotPaused { 
        //accept payment
        IERC20 token = IERC20(paymentTokenAddress);
        uint256 _price = isBoss[_name] ? bossPrice : fighterPrice;
        token.transferFrom(msg.sender, address(this), _price);
        
        // regenerate random seed
        RandomNumberConsumer rnc = RandomNumberConsumer(rncAddress);
        rnc.getRandomNumber();
        
        // mint NFT
        ICT nft = ICT(nftAddress);
        uint256 newFighterId = nft.createToken(msg.sender, _name, classFor[_name], syndicateFor[_name], isBoss[_name], 
                                                genAttr[_random(4, 0)], 
                                                isBoss[_name] ? elements[_random(4, 1)] : "", 
                                                potentialMaxFor[_name]);
        _firstLevelUp(newFighterId, _name);

        //distribute to wallets
        uint256 i;
        for (i = 0; i < distributionWallets.length; i++) {
            address payable _wallet = distributionWallets[i];
            token.transfer(address(_wallet), uint256(_price * uint256(walletPercentage[address(_wallet)]) / 100));
        }
    }

    receive() external payable {
        
    }
    
    fallback() external payable {
        
    }
    
    function withdrawBalance(uint256 _amount) external onlyContractOwner {
        payable(owner).transfer(_amount);
    }
    
    function withdrawTokenBalance(address token_address, uint256 _amount) external onlyContractOwner {
        IERC20 token = IERC20(token_address);
        token.transfer(owner, _amount);
    }
   
}