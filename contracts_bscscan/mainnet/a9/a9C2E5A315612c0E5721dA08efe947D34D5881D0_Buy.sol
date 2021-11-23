/**
 *Submitted for verification at BscScan.com on 2021-11-23
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
    function createToken(address _owner, string memory _name, string memory _class, string memory _tag, uint16 _potentialMax) public virtual returns (uint256);
    function levelUp(uint256 _nft, uint8 _ts, uint8 _a, uint8 _h, uint8 _t, uint16 _potentialMax) public virtual;
}

contract Buy {
    
    bool public paused = false;
    address public owner;
    address public newContractOwner;
    
    address public nftAddress;
    address public rncAddress;
    // address public paymentTokenAddress;
    address payable[] public distributionWallets;
    mapping(address => uint8) public walletPercentage;

    mapping (string => uint256) public priceFor;
    mapping (string => string) classFor;
    mapping (string => uint16) potentialMaxFor;
    mapping (string => string) tagFor;
    mapping (string => mapping (string => uint8[])) public initialRanges;
 
    event Pause();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor (address _nftAddress, address _rncAddress) {
        owner = msg.sender;
        nftAddress = _nftAddress;
        rncAddress = _rncAddress;
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
    
    function addAvatar(string memory _name, string memory _tagFor, string memory _class, uint16 _potentialMax, uint256 _price) public onlyContractOwner ifNotPaused {
        classFor[_name] = _class;
        tagFor[_name] = _tagFor;
        potentialMaxFor[_name] = _potentialMax;
        priceFor[_name] = _price;
    }
    
    function setRanges(string memory _rangeId, uint8 _topSpeedMin, uint8 _topSpeedMax, uint8 _accelerationMin, uint8 _accelerationMax, 
                        uint8 _handlingMin, uint8 _handlingMax, uint8 _tractionMin, uint8 _tractionMax) public onlyContractOwner ifNotPaused {
        initialRanges[_rangeId]["top_speed"] = [_topSpeedMin, _topSpeedMax];
        initialRanges[_rangeId]["acceleration"] = [_accelerationMin, _accelerationMax];
        initialRanges[_rangeId]["handling"] = [_handlingMin, _handlingMax];
        initialRanges[_rangeId]["traction"] = [_tractionMin, _tractionMax];
    }
    
    ////////////////// BUY CONTRACT ////////////////////
 
    // function setPaymentToken(address _tokenAddress) external onlyContractOwner {
    //     paymentTokenAddress = _tokenAddress;
    // }
    
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
    
    function _firstLevelUp(uint256 _newVehicleId, string memory _name) internal {
        ICT nft = ICT(nftAddress);
        uint8 _top_speed = _random(initialRanges[_name]["top_speed"], 1);
        uint8 _acceleration = _random(initialRanges[_name]["acceleration"], 2);
        uint8 _handling = _random(initialRanges[_name]["handling"], 3);
        uint8 _traction = _random(initialRanges[_name]["traction"], 4);
        
        uint16 attrs_sum = uint16(_top_speed + _acceleration + _handling + _traction);
        uint16 potentialMax = uint16(118 + attrs_sum);
        
        nft.levelUp(_newVehicleId, _top_speed, _acceleration, _handling, _traction, potentialMax);
    }
 
    function buyNFT(string memory _name) external payable ifNotPaused { 
        //accept payment
        //IERC20 token = IERC20(paymentTokenAddress);
        //token.transferFrom(msg.sender, address(this), priceFor[_name]);
        require(msg.value >= priceFor[_name]);
        
        // regenerate random seed
        RandomNumberConsumer rnc = RandomNumberConsumer(rncAddress);
        rnc.getRandomNumber();
        
        // mint NFT
        ICT nft = ICT(nftAddress);
        uint256 newNFTId = nft.createToken(msg.sender, _name, classFor[_name], tagFor[_name], potentialMaxFor[_name]);
        _firstLevelUp(newNFTId, _name);

        //distribute to wallets
        uint256 i;
        for (i = 0; i < distributionWallets.length; i++) {
            address payable _wallet = distributionWallets[i];
            if (_wallet != address(0) || walletPercentage[_wallet] > 0) {
                _wallet.transfer(uint256(priceFor[_name] * uint256(walletPercentage[_wallet]) / 100));
            }
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