/* ==================================================================== */
/* Copyright (c) 2018 The TokenTycoon Project.  All rights reserved.
/* 
/* https://tokentycoon.io
/*  
/* authors <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="8bf9e2e8e0e3fee5ffeef9a5f8e3eee5cbece6eae2e7a5e8e4e6">[email&#160;protected]</a>   
/*         <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fc8f8f998f89929895929bbc9b919d9590d29f9391">[email&#160;protected]</a>            
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

/// This Random is inspired by https://github.com/axiomzen/eth-random
contract Random {
    uint256 _seed;

    function _rand() internal returns (uint256) {
        _seed = uint256(keccak256(abi.encodePacked(_seed, blockhash(block.number - 1), block.coinbase, block.difficulty)));
        return _seed;
    }

    function _randBySeed(uint256 _outSeed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_outSeed, blockhash(block.number - 1), block.coinbase, block.difficulty)));
    }
}


contract TTLottery is AccessService, Random {
    TTCInterface ttcToken;
    ManagerTokenInterface ttmToken;
    WonderTokenInterface ttwToken;
    TalentCardInterface tttcToken;

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

    event LotteryResult(
        address indexed buyer,
        address indexed buyTo,
        uint256 lotteryCount,
        uint256 lotteryRet
    );

    constructor() public {
        addrAdmin = msg.sender;
        addrFinance = msg.sender;
        addrService = msg.sender;

        ttcToken = TTCInterface(0xfB673F08FC82807b4D0E139e794e3b328d63551f);
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

    function setTalentCardAddress(address _addr) external onlyAdmin {
        require(_addr != address(0));
        tttcToken = TalentCardInterface(_addr);
    }
    
    mapping (address => uint64) public lotteryHistory; 

    uint64 public nextLotteryTTMTokenId4 = 211;         // ManagerId: 4, tokenId: 211~285, lotteryRet:4 
    uint64 public nextLotteryTTMTokenId5 = 286;         // ManagerId: 5, tokenId: 286~360, lotteryRet:5
    uint64 public nextLotteryTTMTokenId9 = 511;         // ManagerId: 9, tokenId: 511~560, lotteryRet:6
    uint64 public nextLotteryTTMTokenId10 = 561;        // ManagerId:10, tokenId: 561~610, lotteryRet:7

    uint64 public nextLotteryTTWTokenId3 = 91;          // WonderId:  3, tokenId:  91~150, lotteryRet:8
    uint64 public nextLotteryTTWTokenId4 = 151;         // WonderId:  4, tokenId: 151~180, lotteryRet:9

    function setNextLotteryTTMTokenId4(uint64 _val) external onlyAdmin {
        require(nextLotteryTTMTokenId4 >= 211 && nextLotteryTTMTokenId4 <= 286);
        nextLotteryTTMTokenId4 = _val;
    }

    function setNextLotteryTTMTokenId5(uint64 _val) external onlyAdmin {
        require(nextLotteryTTMTokenId5 >= 286 && nextLotteryTTMTokenId5 <= 361);
        nextLotteryTTMTokenId5 = _val;
    }

    function setNextLotteryTTMTokenId9(uint64 _val) external onlyAdmin {
        require(nextLotteryTTMTokenId9 >= 511 && nextLotteryTTMTokenId9 <= 561);
        nextLotteryTTMTokenId9 = _val;
    }

    function setNextLotteryTTMTokenId10(uint64 _val) external onlyAdmin {
        require(nextLotteryTTMTokenId10 >= 561 && nextLotteryTTMTokenId10 <= 611);
        nextLotteryTTMTokenId10 = _val;
    }

    function setNextLotteryTTWTokenId3(uint64 _val) external onlyAdmin {
        require(nextLotteryTTWTokenId3 >= 91 && nextLotteryTTWTokenId3 <= 151);
        nextLotteryTTWTokenId3 = _val;
    }

    function setNextLotteryTTWTokenId4(uint64 _val) external onlyAdmin {
        require(nextLotteryTTWTokenId4 >= 151 && nextLotteryTTWTokenId4 <= 181);
        nextLotteryTTWTokenId4 = _val;
    }

    function _getExtraParam(bytes _extraData) 
        private 
        pure
        returns(address addr, uint256 lotteryCount) 
    {
        assembly { addr := mload(add(_extraData, 20)) } 
        lotteryCount = uint256(_extraData[20]);
    }

    function receiveApproval(address _sender, uint256 _value, address _token, bytes _extraData) 
        external
        whenNotPaused 
    {
        require(msg.sender == address(ttcToken));
        require(_extraData.length == 21);
        (address toAddr, uint256 lotteryCount) = _getExtraParam(_extraData);
        require(ttcToken.transferFrom(_sender, address(this), _value));
        if (lotteryCount == 1) {
            _lottery(_value, toAddr, _sender);
        } else if(lotteryCount == 5) {
            _lottery5(_value, toAddr, _sender);
        } else {
            require(false, "Invalid lottery count");
        }
    }

    function lotteryByETH(address _gameWalletAddr) 
        external 
        payable
        whenNotPaused 
    {
        _lottery(msg.value, _gameWalletAddr, msg.sender);
    }

    function lotteryByETH5(address _gameWalletAddr) 
        external 
        payable
        whenNotPaused 
    {
        _lottery5(msg.value, _gameWalletAddr, msg.sender);
    }

    function _lotteryCard(uint256 _seed, address _gameWalletAddr) 
        private 
        returns(uint256 lotteryRet)
    {
        uint256 rdm = _seed % 10000;
        if (rdm < 6081) {
            tttcToken.safeSendCard(1, _gameWalletAddr);
            lotteryRet = 1;
        } else if (rdm < 8108) {
            tttcToken.safeSendCard(3, _gameWalletAddr);
            lotteryRet = 2;
        } else if (rdm < 9324) {
            tttcToken.safeSendCard(5, _gameWalletAddr);
            lotteryRet = 3;
        } else {
            tttcToken.safeSendCard(10, _gameWalletAddr);
            lotteryRet = 4;
        }
    }

    function _lotteryCardNoSend(uint256 _seed)
        private
        pure 
        returns(uint256 lotteryRet, uint256 cardCnt) 
    {
        uint256 rdm = _seed % 10000;
        if (rdm < 6081) {
            cardCnt = 1;
            lotteryRet = 1;
        } else if (rdm < 8108) {
            cardCnt = 3;
            lotteryRet = 2;
        } else if (rdm < 9324) {
            cardCnt = 5;
            lotteryRet = 3;
        } else {
            cardCnt = 10;
            lotteryRet = 4;
        }
    }

    function _lotteryToken(uint256 _seed, address _gameWalletAddr, address _buyer) 
        private 
        returns(uint256 lotteryRet) 
    {
        uint256[6] memory weightArray;
        uint256 totalWeight = 0;
        if (nextLotteryTTMTokenId4 <= 285) {
            totalWeight += 2020;
            weightArray[0] = totalWeight;
        }
        if (nextLotteryTTMTokenId5 <= 360) {
            totalWeight += 2020;
            weightArray[1] = totalWeight;
        }
        if (nextLotteryTTMTokenId9 <= 560) {
            totalWeight += 1340;
            weightArray[2] = totalWeight;
        }
        if (nextLotteryTTMTokenId10 <= 610) {
            totalWeight += 1340;
            weightArray[3] = totalWeight;
        }
        if (nextLotteryTTWTokenId3 <= 150) {
            totalWeight += 2220;
            weightArray[4] = totalWeight;
        }
        if (nextLotteryTTWTokenId4 <= 180) {
            totalWeight += 1000;
            weightArray[5] = totalWeight;
        }

        if (totalWeight > 0) {
            uint256 rdm = _seed % totalWeight;
            for (uint32 i = 0; i < 6; ++i) {
                if (weightArray[i] == 0 || rdm >= weightArray[i]) {
                    continue;
                }
                if (i == 0) {
                    nextLotteryTTMTokenId4 += 1;
                    ttmToken.safeGiveByContract(nextLotteryTTMTokenId4 - 1, _gameWalletAddr);
                    emit ManagerSold(_buyer, _gameWalletAddr, 4, nextLotteryTTMTokenId4);
                } else if (i == 1) {
                    nextLotteryTTMTokenId5 += 1;
                    ttmToken.safeGiveByContract(nextLotteryTTMTokenId5 - 1, _gameWalletAddr);
                    emit ManagerSold(_buyer, _gameWalletAddr, 5, nextLotteryTTMTokenId5);
                } else if (i == 2) {
                    nextLotteryTTMTokenId9 += 1;
                    ttmToken.safeGiveByContract(nextLotteryTTMTokenId9 - 1, _gameWalletAddr);
                    emit ManagerSold(_buyer, _gameWalletAddr, 9, nextLotteryTTMTokenId9);
                } else if (i == 3) {
                    nextLotteryTTMTokenId10 += 1;
                    ttmToken.safeGiveByContract(nextLotteryTTMTokenId10 - 1, _gameWalletAddr);
                    emit ManagerSold(_buyer, _gameWalletAddr, 10, nextLotteryTTMTokenId10);
                } else if (i == 4) {
                    nextLotteryTTWTokenId3 += 1;
                    ttwToken.safeGiveByContract(nextLotteryTTWTokenId3 - 1, _gameWalletAddr);
                    emit WonderSold(_buyer, _gameWalletAddr, 3, nextLotteryTTWTokenId3);
                } else {
                    nextLotteryTTWTokenId4 += 1;
                    ttwToken.safeGiveByContract(nextLotteryTTWTokenId4 - 1, _gameWalletAddr);
                    emit WonderSold(_buyer, _gameWalletAddr, 4, nextLotteryTTWTokenId4);
                }
                lotteryRet = i + 5;
                break;
            } 
        }
    }

    function _lottery(uint256 _value, address _gameWalletAddr, address _buyer) 
        private 
    {
        require(_value == 0.039 ether);
        require(_gameWalletAddr != address(0));

        uint256 lotteryRet;
        uint256 seed = _rand();
        uint256 rdm = seed % 10000;
        seed /= 10000;
        if (rdm < 400) {
            lotteryRet = _lotteryToken(seed, _gameWalletAddr, _buyer);
            if (lotteryRet == 0) {
                lotteryRet = _lotteryCard(seed, _gameWalletAddr);
            }
        } else {
            lotteryRet = _lotteryCard(seed, _gameWalletAddr);
        }
        lotteryHistory[_gameWalletAddr] = uint64(lotteryRet);
        emit LotteryResult(_buyer, _gameWalletAddr, 1, lotteryRet);
    }

    function _lottery5(uint256 _value, address _gameWalletAddr, address _buyer) 
        private 
    {
        require(_value == 0.1755 ether);
        require(_gameWalletAddr != address(0));

        uint256 seed = _rand();
        uint256 lotteryRet = 0;
        uint256 lRet;
        uint256 cardCountTotal = 0;
        uint256 cardCount;
        for (uint256 i = 0; i < 5; ++i) {
            if (i > 0) {
                seed = _randBySeed(seed);
            }
            uint256 rdm = seed % 10000;
            seed /= 10000;
            if (rdm < 400) {
                lRet = _lotteryToken(seed, _gameWalletAddr, _buyer);
                if (lRet == 0) {
                    (lRet, cardCount) = _lotteryCardNoSend(seed);
                    cardCountTotal += cardCount;
                }
                lotteryRet += (lRet * (100 ** i));
            } else {
                (lRet, cardCount) = _lotteryCardNoSend(seed);
                cardCountTotal += cardCount;
                lotteryRet += (lRet * (100 ** i));
            }
        }

        require(cardCountTotal <= 50);

        if (cardCountTotal > 0) {
            tttcToken.safeSendCard(cardCountTotal, _gameWalletAddr);
        }
        lotteryHistory[_gameWalletAddr] = uint64(lotteryRet);

        emit LotteryResult(_buyer, _gameWalletAddr, 5, lotteryRet);
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

    function getLotteryInfo(address _walletAddr)
        external
        view 
        returns(
           uint64 ttmCnt4,
           uint64 ttmCnt5,
           uint64 ttmCnt9,
           uint64 ttmCnt10,
           uint64 ttWCnt3,
           uint64 ttwCnt4, 
           uint64 lastLottery
        )
    {
        ttmCnt4 = 286 - nextLotteryTTMTokenId4;
        ttmCnt5 = 361 - nextLotteryTTMTokenId5;
        ttmCnt9 = 561 - nextLotteryTTMTokenId9;
        ttmCnt10 = 611 - nextLotteryTTMTokenId10;
        ttWCnt3 = 151 - nextLotteryTTWTokenId3;
        ttwCnt4 = 181 - nextLotteryTTWTokenId4;
        lastLottery = lotteryHistory[_walletAddr];
    }
}