/* ==================================================================== */
/* Copyright (c) 2018 The TokenTycoon Project.  All rights reserved.
/* 
/* https://tokentycoon.io
/*  
/* authors <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7e0c171d15160b100a1b0c500d161b103e19131f1712501d1113">[email&#160;protected]</a>   
/*         <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9fececfaeceaf1fbf6f1f8dff8f2fef6f3b1fcf0f2">[email&#160;protected]</a>            
/* ==================================================================== */

pragma solidity ^0.4.23;

contract AccessAdmin {
    bool public isPaused = false;
    address public addrAdmin;  

    event AdminTransferred(address indexed preAdmin, address indexed newAdmin);

    constructor() public {
        addrAdmin = msg.sender;
    }  


    modifier onlyAdmin() {
        require(msg.sender == addrAdmin);
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused);
        _;
    }

    modifier whenPaused {
        require(isPaused);
        _;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0));
        emit AdminTransferred(addrAdmin, _newAdmin);
        addrAdmin = _newAdmin;
    }

    function doPause() external onlyAdmin whenNotPaused {
        isPaused = true;
    }

    function doUnpause() external onlyAdmin whenPaused {
        isPaused = false;
    }
}

contract AccessService is AccessAdmin {
    address public addrService;
    address public addrFinance;

    modifier onlyService() {
        require(msg.sender == addrService);
        _;
    }

    modifier onlyFinance() {
        require(msg.sender == addrFinance);
        _;
    }

    function setService(address _newService) external {
        require(msg.sender == addrService || msg.sender == addrAdmin);
        require(_newService != address(0));
        addrService = _newService;
    }

    function setFinance(address _newFinance) external {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        require(_newFinance != address(0));
        addrFinance = _newFinance;
    }

    function withdraw(address _target, uint256 _amount) 
        external 
    {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        require(_amount > 0);
        address receiver = _target == address(0) ? addrFinance : _target;
        uint256 balance = address(this).balance;
        if (_amount < balance) {
            receiver.transfer(_amount);
        } else {
            receiver.transfer(address(this).balance);
        }      
    }
}

interface WarTokenInterface {
    function getFashion(uint256 _tokenId) external view returns(uint16[12]);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferByContract(uint256 _tokenId, address _to) external;
} 

interface WonderTokenInterface {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function safeGiveByContract(uint256 _tokenId, address _to) external;
    function getProtoIdByTokenId(uint256 _tokenId) external view returns(uint256); 
}

interface ManagerTokenInterface {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function safeGiveByContract(uint256 _tokenId, address _to) external;
    function getProtoIdByTokenId(uint256 _tokenId) external view returns(uint256);
}

interface TalentCardInterface {
    function safeSendCard(uint256 _amount, address _to) external;
}

interface ERC20BaseInterface {
    function balanceOf(address _from) external view returns(uint256);
    function transfer(address _to, uint256 _value) external;
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external; 
}

contract TTCInterface is ERC20BaseInterface {
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) external returns (bool);
}

contract TTPresale is AccessService {
    TTCInterface ttcToken;
    WarTokenInterface warToken;
    ManagerTokenInterface ttmToken;
    WonderTokenInterface ttwToken;

    event ManagerSold(
        address indexed buyer,
        address indexed buyTo,
        uint256 mgrId,
        uint256 nextTokenId
    );

    event WonderSold(
        address indexed buyer,
        address indexed buyTo,
        uint256 wonderId,
        uint256 nextTokenId
    );

    constructor() public {
        addrAdmin = msg.sender;
        addrFinance = msg.sender;
        addrService = msg.sender;

        ttcToken = TTCInterface(0xfB673F08FC82807b4D0E139e794e3b328d63551f);
        warToken = WarTokenInterface(0xDA9c03dFd4D137F926c3cF6953cb951832Eb08b2);
    }

    function() external payable {

    }

    uint64 public nextDiscountTTMTokenId1 = 1;      // ManagerId: 1, tokenId:   1~50
    uint64 public nextDiscountTTMTokenId6 = 361;    // ManagerId: 6, tokenId: 361~390
    uint64 public nextCommonTTMTokenId2 = 51;       // ManagerId: 2, tokenId:  51~130
    uint64 public nextCommonTTMTokenId3 = 131;      // ManagerId: 3, tokenId: 131~210
    uint64 public nextCommonTTMTokenId7 = 391;      // ManagerId: 7, tokenId: 391~450
    uint64 public nextCommonTTMTokenId8 = 451;      // ManagerId: 8, tokenId: 451~510
    uint64 public nextDiscountTTWTokenId1 = 1;      // WonderId:  1, tokenId:   1~30
    uint64 public nextCommonTTWTokenId2 = 31;       // WonderId:  2, tokenId:  31-90

    function setNextDiscountTTMTokenId1(uint64 _val) external onlyAdmin {
        require(nextDiscountTTMTokenId1 >= 1 && nextDiscountTTMTokenId1 <= 51);
        nextDiscountTTMTokenId1 = _val;
    }

    function setNextDiscountTTMTokenId6(uint64 _val) external onlyAdmin {
        require(nextDiscountTTMTokenId6 >= 361 && nextDiscountTTMTokenId6 <= 391);
        nextDiscountTTMTokenId6 = _val;
    }

    function setNextCommonTTMTokenId2(uint64 _val) external onlyAdmin {
        require(nextCommonTTMTokenId2 >= 51 && nextCommonTTMTokenId2 <= 131);
        nextCommonTTMTokenId2 = _val;
    }

    function setNextCommonTTMTokenId3(uint64 _val) external onlyAdmin {
        require(nextCommonTTMTokenId3 >= 131 && nextCommonTTMTokenId3 <= 211);
        nextCommonTTMTokenId3 = _val;
    }

    function setNextCommonTTMTokenId7(uint64 _val) external onlyAdmin {
        require(nextCommonTTMTokenId7 >= 391 && nextCommonTTMTokenId7 <= 451);
        nextCommonTTMTokenId7 = _val;
    }

    function setNextCommonTTMTokenId8(uint64 _val) external onlyAdmin {
        require(nextCommonTTMTokenId8 >= 451 && nextCommonTTMTokenId8 <= 511);
        nextCommonTTMTokenId8 = _val;
    }

    function setNextDiscountTTWTokenId1(uint64 _val) external onlyAdmin {
        require(nextDiscountTTWTokenId1 >= 1 && nextDiscountTTWTokenId1 <= 31);
        nextDiscountTTWTokenId1 = _val;
    }

    function setNextCommonTTWTokenId2(uint64 _val) external onlyAdmin {
        require(nextCommonTTWTokenId2 >= 31 && nextCommonTTWTokenId2 <= 91);
        nextCommonTTWTokenId2 = _val;
    }

    uint64 public endDiscountTime = 0;

    function setDiscountTime(uint64 _endTime) external onlyAdmin {
        require(_endTime > block.timestamp);
        endDiscountTime = _endTime;
    }

    function setWARTokenAddress(address _addr) external onlyAdmin {
        require(_addr != address(0));
        warToken = WarTokenInterface(_addr);
    }

    function setTTMTokenAddress(address _addr) external onlyAdmin {
        require(_addr != address(0));
        ttmToken = ManagerTokenInterface(_addr);
    }

    function setTTWTokenAddress(address _addr) external onlyAdmin {
        require(_addr != address(0));
        ttwToken = WonderTokenInterface(_addr);
    }

    function setTTCTokenAddress(address _addr) external onlyAdmin {
        require(_addr != address(0));
        ttcToken = TTCInterface(_addr);
    }

    function _getExtraParam(bytes _extraData) 
        private 
        pure
        returns(address addr, uint64 f, uint256 protoId) 
    {
        assembly { addr := mload(add(_extraData, 20)) } 
        f = uint64(_extraData[20]);
        protoId = uint256(_extraData[21]) * 256 + uint256(_extraData[22]);
    }

    function receiveApproval(address _sender, uint256 _value, address _token, bytes _extraData) 
        external
        whenNotPaused 
    {
        require(msg.sender == address(ttcToken));
        require(_extraData.length == 23);
        (address toAddr, uint64 f, uint256 protoId) = _getExtraParam(_extraData);
        require(ttcToken.transferFrom(_sender, address(this), _value));
        if (f == 0) {
            _buyDiscountTTM(_value, protoId, toAddr, _sender);
        } else if (f == 1) {
            _buyDiscountTTW(_value, protoId, toAddr, _sender);
        } else if (f == 2) {
            _buyCommonTTM(_value, protoId, toAddr, _sender);
        } else if (f == 3) {
            _buyCommonTTW(_value, protoId, toAddr, _sender);
        } else {
            require(false, "Invalid func id");
        }
    }

    function exchangeByPet(uint256 _warTokenId, uint256 _mgrId, address _gameWalletAddr)  
        external
        whenNotPaused
    {
        require(warToken.ownerOf(_warTokenId) == msg.sender);
        uint16[12] memory warData = warToken.getFashion(_warTokenId);
        uint16 protoId = warData[0];
        if (_mgrId == 2) {
            require(protoId == 10001 || protoId == 10003);
            require(nextCommonTTMTokenId2 <= 130);
            warToken.safeTransferByContract(_warTokenId, address(this));
            nextCommonTTMTokenId2 += 1;
            ttmToken.safeGiveByContract(nextCommonTTMTokenId2 - 1, _gameWalletAddr);
            emit ManagerSold(msg.sender, _gameWalletAddr, 2, nextCommonTTMTokenId2);
        } else if (_mgrId == 3) {
            require(protoId == 10001 || protoId == 10003);
            require(nextCommonTTMTokenId3 <= 210);
            warToken.safeTransferByContract(_warTokenId, address(this));
            nextCommonTTMTokenId3 += 1;
            ttmToken.safeGiveByContract(nextCommonTTMTokenId3 - 1, _gameWalletAddr);
            emit ManagerSold(msg.sender, _gameWalletAddr, 3, nextCommonTTMTokenId3);
        } else if (_mgrId == 7) {
            require(protoId == 10002 || protoId == 10004 || protoId == 10005);
            require(nextCommonTTMTokenId7 <= 450);
            warToken.safeTransferByContract(_warTokenId, address(this));
            nextCommonTTMTokenId7 += 1;
            ttmToken.safeGiveByContract(nextCommonTTMTokenId7 - 1, _gameWalletAddr);
            emit ManagerSold(msg.sender, _gameWalletAddr, 7, nextCommonTTMTokenId7);
        } else if (_mgrId == 8) {
            require(protoId == 10002 || protoId == 10004 || protoId == 10005);
            require(nextCommonTTMTokenId8 <= 510);
            warToken.safeTransferByContract(_warTokenId, address(this));
            nextCommonTTMTokenId8 += 1;
            ttmToken.safeGiveByContract(nextCommonTTMTokenId8 - 1, _gameWalletAddr);
            emit ManagerSold(msg.sender, _gameWalletAddr, 8, nextCommonTTMTokenId8);
        } else {
            require(false);
        }
    }

    function buyDiscountTTMByETH(uint256 _mgrId, address _gameWalletAddr) 
        external 
        payable
        whenNotPaused 
    {
        _buyDiscountTTM(msg.value, _mgrId, _gameWalletAddr, msg.sender);
    }

    function buyDiscountTTWByETH(uint256 _wonderId, address _gameWalletAddr) 
        external 
        payable
        whenNotPaused 
    {
        _buyDiscountTTW(msg.value, _wonderId, _gameWalletAddr, msg.sender);
    }
    
    function buyCommonTTMByETH(uint256 _mgrId, address _gameWalletAddr) 
        external
        payable
        whenNotPaused
    {
        _buyCommonTTM(msg.value, _mgrId, _gameWalletAddr, msg.sender);
    }

    function buyCommonTTWByETH(uint256 _wonderId, address _gameWalletAddr) 
        external
        payable
        whenNotPaused
    {
        _buyCommonTTW(msg.value, _wonderId, _gameWalletAddr, msg.sender);
    }

    function _buyDiscountTTM(uint256 _value, uint256 _mgrId, address _gameWalletAddr, address _buyer) 
        private  
    {
        require(_gameWalletAddr != address(0));
        if (_mgrId == 1) {
            require(nextDiscountTTMTokenId1 <= 50, "This Manager is sold out");
            if (block.timestamp <= endDiscountTime) {
                require(_value == 0.64 ether);
            } else {
                require(_value == 0.99 ether);
            }
            nextDiscountTTMTokenId1 += 1;
            ttmToken.safeGiveByContract(nextDiscountTTMTokenId1 - 1, _gameWalletAddr);
            emit ManagerSold(_buyer, _gameWalletAddr, 1, nextDiscountTTMTokenId1);
        } else if (_mgrId == 6) {
            require(nextDiscountTTMTokenId6 <= 390, "This Manager is sold out");
            if (block.timestamp <= endDiscountTime) {
                require(_value == 0.97 ether);
            } else {
                require(_value == 1.49 ether);
            }
            nextDiscountTTMTokenId6 += 1;
            ttmToken.safeGiveByContract(nextDiscountTTMTokenId6 - 1, _gameWalletAddr);
            emit ManagerSold(_buyer, _gameWalletAddr, 6, nextDiscountTTMTokenId6);
        } else {
            require(false);
        }
    }

    function _buyDiscountTTW(uint256 _value, uint256 _wonderId, address _gameWalletAddr, address _buyer) 
        private 
    {
        require(_gameWalletAddr != address(0));
        require(_wonderId == 1); 

        require(nextDiscountTTWTokenId1 <= 30, "This Manager is sold out");
        if (block.timestamp <= endDiscountTime) {
            require(_value == 0.585 ether);
        } else {
            require(_value == 0.90 ether);
        }
        nextDiscountTTWTokenId1 += 1;
        ttwToken.safeGiveByContract(nextDiscountTTWTokenId1 - 1, _gameWalletAddr);
        emit WonderSold(_buyer, _gameWalletAddr, 1, nextDiscountTTWTokenId1);
    }
    
    function _buyCommonTTM(uint256 _value, uint256 _mgrId, address _gameWalletAddr, address _buyer) 
        private
    {
        require(_gameWalletAddr != address(0));
        if (_mgrId == 2) {
            require(nextCommonTTMTokenId2 <= 130);
            require(_value == 0.99 ether);
            nextCommonTTMTokenId2 += 1;
            ttmToken.safeGiveByContract(nextCommonTTMTokenId2 - 1, _gameWalletAddr);
            emit ManagerSold(_buyer, _gameWalletAddr, 2, nextCommonTTMTokenId2);
        } else if (_mgrId == 3) {
            require(nextCommonTTMTokenId3 <= 210);
            require(_value == 0.99 ether);
            nextCommonTTMTokenId3 += 1;
            ttmToken.safeGiveByContract(nextCommonTTMTokenId3 - 1, _gameWalletAddr);
            emit ManagerSold(_buyer, _gameWalletAddr, 3, nextCommonTTMTokenId3);
        } else if (_mgrId == 7) {
            require(nextCommonTTMTokenId7 <= 450);
            require(_value == 1.49 ether);
            nextCommonTTMTokenId7 += 1;
            ttmToken.safeGiveByContract(nextCommonTTMTokenId7 - 1, _gameWalletAddr);
            emit ManagerSold(_buyer, _gameWalletAddr, 7, nextCommonTTMTokenId7);
        } else if (_mgrId == 8) {
            require(nextCommonTTMTokenId8 <= 510);
            require(_value == 1.49 ether);
            nextCommonTTMTokenId8 += 1;
            ttmToken.safeGiveByContract(nextCommonTTMTokenId8 - 1, _gameWalletAddr);
            emit ManagerSold(_buyer, _gameWalletAddr, 8, nextCommonTTMTokenId8);
        } else {
            require(false);
        }
    }

    function _buyCommonTTW(uint256 _value, uint256 _wonderId, address _gameWalletAddr, address _buyer) 
        private
    {
        require(_gameWalletAddr != address(0));
        require(_wonderId == 2); 
        require(nextCommonTTWTokenId2 <= 90);
        require(_value == 0.50 ether);
        nextCommonTTWTokenId2 += 1;
        ttwToken.safeGiveByContract(nextCommonTTWTokenId2 - 1, _gameWalletAddr);
        emit WonderSold(_buyer, _gameWalletAddr, 2, nextCommonTTWTokenId2);
    }

    function withdrawERC20(address _erc20, address _target, uint256 _amount)
        external
    {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        require(_amount > 0);
        address receiver = _target == address(0) ? addrFinance : _target;
        ERC20BaseInterface erc20Contract = ERC20BaseInterface(_erc20);
        uint256 balance = erc20Contract.balanceOf(address(this));
        require(balance > 0);
        if (_amount < balance) {
            erc20Contract.transfer(receiver, _amount);
        } else {
            erc20Contract.transfer(receiver, balance);
        }   
    }

    function getPresaleInfo() 
        external 
        view 
        returns(
            uint64 ttmCnt1,
            uint64 ttmCnt2,
            uint64 ttmCnt3,
            uint64 ttmCnt6,
            uint64 ttmCnt7,
            uint64 ttmCnt8,
            uint64 ttwCnt1,
            uint64 ttwCnt2,
            uint64 discountEnd
        )
    {
        ttmCnt1 = 51 - nextDiscountTTMTokenId1;
        ttmCnt2 = 131 - nextCommonTTMTokenId2;
        ttmCnt3 = 211 - nextCommonTTMTokenId3;
        ttmCnt6 = 391 - nextDiscountTTMTokenId6;
        ttmCnt7 = 451 - nextCommonTTMTokenId7;
        ttmCnt8 = 511 - nextCommonTTMTokenId8;
        ttwCnt1 = 31 - nextDiscountTTWTokenId1;
        ttwCnt2 = 91 - nextCommonTTWTokenId2;
        discountEnd = endDiscountTime;
    }
}