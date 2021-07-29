// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./TokenTimelock.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract EzraToken is ERC20, AccessControl, Ownable {
    using SafeMath for uint256;
    
    // 락업 구조체
    struct lockAllowance {
        uint256 total;
        uint256 allowance;
        // uint256 spent;
        uint256 sendToken;
        uint lockStage;
    }

    // 토큰 발행 개수
    uint256 public constant INITIAL_SUPPLY = 21000000;

    // 유저들 지갑
    address public user_wallet = payable(msg.sender);
    
    // 권한 암호화 문자
    bytes32 public constant MINTER_ROLE = keccak256("MINT");
    bytes32 public constant BURNER_ROLE = keccak256("BURN");

    // false면 이동잠금기간
    bool public released = false;

    // 락업이 설정 되었는지 여부
    bool public lockRegist = false;

    // 락업 지갑 소유주
    address public lockOwner;

    // 토큰 처음 만들어진 시간
    uint256 firstListingDate;

    // 해당 지갑 토큰을 잠그기
    mapping(address => lockAllowance) lockAllowances;
    // mapping(address => bool) public earlyInvestors;

    // 토큰전송
    mapping(address => uint256) public sendAmount; // 토큰을 얼마나 보냈는 지 확인을 위한 변수
    event SendToken(address from, address to, uint256 amount);

    // 토큰취소
    mapping(address => uint256) public cancelAmount; // 취소된 토큰 양

    // 에어드랍
    mapping(address => uint256) public airDropHistory; // 에어드랍량을 알기 위한 변수
    event AirDrop(address _receiveWallet, uint256 amount);

    // 이동잠금기간이면 권한을 우선 확인
    modifier canTransfer() {
        if(!released){
            require(lockOwner == msg.sender, "You do not have permission");
        }
        _;
    }
    
    // 락업한 계정의 지갑 주인인지 확인
    modifier onlyLockOwner() {
        require(lockOwner == msg.sender, "You do not have permission");
        _;
    }

    // 거래가능인지 확인
    // modifier investorChecks(uint256 _value) {
    modifier investorChecks() {
        // if(firstListingDate + 30 days < block.timestamp){
            // if(earlyInvestors[msg.sender]){
            if(lockRegist){
                updateLockAllowances();
                // lockAllowance storage lock = lockAllowances[msg.sender];
                // require(lock.spent <= _value);
                // updateLockSpent(_value);
            }
        // }
        _;
    }


    // 토큰 이름 설정
    constructor () ERC20("EzraToken", "EZT") {
        address owners = payable(msg.sender); // 지갑 주인

        _mint(msg.sender, INITIAL_SUPPLY * 10 ** (uint(decimals()))); // 토큰 발행

        _setupRole(MINTER_ROLE, owners); // 지갑 주인 생성 권한
        _setupRole(BURNER_ROLE, owners); // 지갑 주인 소각 권한
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // grantrole에 소각이나 생성을 할 권한을 부여
        
        firstListingDate = block.timestamp; // 토큰 처음 만들어진 시간
        setReleaser(msg.sender); // 락업 권한 부여
        addToLock(INITIAL_SUPPLY, owners); // 락업 추가
    }

    // 토큰 이름
    /**
     *   @dev 토큰 이름 조회
     *   @return 해당 토큰 이름 반환
     */
    function tokenName() public view returns(string memory) {
        return name();
    }

    // 토큰 심볼
    /**
     *   @dev 토큰 심볼 조회
     *   @return 해당 토큰 심볼 반환
     */    
    function tokenSymbol() public view returns(string memory){
        return symbol();
    }

    // 토큰 deciamls
    /**
     *   @dev 토큰 개수 소수자리 조회
     *   @return 해당 decimals 반환
     */
    function tokenDecimals() public view returns(uint8) {
        return decimals();
    }

    // 토큰 조회
    /**
     *   @dev 입력한 지갑 주소의 잔액을 조회
     *   @param wallet 조회할 지갑
     *   @return 해당 지갑 수량 반환
     */
    function getBalance(address wallet) public view returns(uint256){
        return balanceOf(wallet);
    }

    // 토큰 전송 - 일반 사용자만 가능
    /**
     *   @dev 일반 사용자만 토큰을 입력한 주소로 보낸다.
     *   @param _to 보낼 주소를 입력
     *   @param _amount 보낼 토큰의 양을 입력
     */
    function sendToken(address _to, uint256 _amount) public {
        require(lockOwner != user_wallet);
        require(balanceOf(user_wallet) >= _amount, "Not enough EZT");
        transfer(_to, _amount);
        sendAmount[user_wallet] += _amount;
        emit SendToken(user_wallet, _to, _amount);
    }

    // 토큰 전송 - 관리자만 가능
    /**
     *   @dev 관리자만 토큰을 입력한 주소로 보낸다.
     *   @param _to 보낼 주소를 입력
     *   @param _amount 보낼 토큰의 양을 입력
     */
    function sendToken_Admin(address _to, uint256 _amount) onlyOwner() canTransfer() investorChecks() public {
        uint256 multi = 10 ** 18;
        lockAllowance storage lock = lockAllowances[msg.sender];
        require(balanceOf(user_wallet) >= _amount, "Not enough EZT");
        require((lock.total - lock.allowance) * multi >= (balanceOf(msg.sender) - _amount));
        transfer(_to, _amount);
        sendAmount[user_wallet] += _amount;
        emit SendToken(user_wallet, _to, _amount);
    }

    // 토큰 발급
    /**
     *   @dev 주소와 토큰 양을 적어서 보낸다. Role에 mint권한이 있는 지 확인 후
     *   _mint 함수에서 토큰을 생성한다.
     *   @param to 받을 지갑 주소
     *   @param _amount 토큰 양
     */
    function tokenMint(address to, uint256 _amount) public onlyRole(MINTER_ROLE) {
        _mint(to, _amount);
    }

    // 토큰 소각
    /**
     *   @dev 주소와 토큰 양을 적어서 보낸다. Role에 burn권한이 있는 지 확인 후
     *   _burn 함수에서 토큰을 생성한다.
     *   @param from 받을 지갑 주소
     *   @param _amount 토큰 양
     */
    function tokenBurn(address from, uint256 _amount) public onlyRole(BURNER_ROLE) {
        _burn(from, _amount);
    }

    // 토큰 에어드랍
    /**
     *   @dev 에어드랍 할 주소를 배열로 받아서 각자 전송할 토큰 목록을 실행한다.
     *   @param receivers 에어드랍 받을 지갑 주소들
     *   @param values 에어드랍 받을 지갑 주소의 토큰 개수
     */
    function tokenAirDrop(address[] memory receivers, uint256[] memory values) public onlyOwner {
        require(receivers.length != 0);
        require(receivers.length == values.length);

        for(uint256 i = 0; i < receivers.length; i++) {
            address receiver = receivers[i];
            uint256 amount = values[i];

            transfer(receiver, amount);
            airDropHistory[receiver] += amount;
            sendAmount[user_wallet] += amount;

            emit AirDrop(receiver, amount);
        }
    }

    // 토큰 정지
    /**
     *   @dev 해당 계약을 일시 중지한다.
     *   @param _from 보내는 지갑 주소
     *   @param _to 받는 지갑 주소
     *   @param _amount 보낸 토큰의 양
     */
    function tokenPause(address _from, address _to, uint256 _amount) public {
        _beforeTokenTransfer(_from, _to, _amount);
        cancelAmount[_from] -= _amount;
    }

/**
     *   @dev 락업을 해체
     */
    function releaseTokenTransfer() onlyLockOwner() public {
        released = true;
    }
    /**
     *   @dev 락업 지갑 주인 설정
     */
    function setReleaser(address _lockOwner) onlyOwner public {
        lockOwner = _lockOwner;
    }
    /**
     *   @dev 락업 추가 2100만개 중 100만개만 우선 허용 나머지는 Lock
     */    
    function addToLock(uint256 _total, address _investor) public onlyLockOwner() {
        // if(!earlyInvestors[_investor]){
        if(!lockRegist){
            lockAllowance memory lock;
            lock.total = _total;
            lock.allowance = 1000000;
            // lock.spent = 0;
            lock.sendToken = 0;
            lockAllowances[_investor] = lock;
            // earlyInvestors[_investor] = true;
            lockRegist = true;
        }else {
            updateLockTotal(_total);
        }
    }
    /**
     *   @dev 락업할 토큰 추가로 업데이트
     */
    function updateLockTotal(uint256 _total) internal returns(bool) {
        lockAllowance storage lock = lockAllowances[msg.sender];
        lock.total = lock.total + _total;
        return true;
    }
    /**
     *   @dev 락업 소비 업데이트
     */
    // function updateLockSpent(uint256 _spent) internal returns(bool) {
    //     lockAllowance storage lock = lockAllowances[msg.sender];
    //     lock.spent = lock.spent + _spent;
    //     return true;
    // }
    /**
     *   @dev 락업 물량 업데이트
     */
    function updateLockAllowances() internal returns(bool) {
        lockAllowance storage lock = lockAllowances[msg.sender];
        if(firstListingDate + 30 days >= block.timestamp && firstListingDate + 60 days < block.timestamp){
            if(lock.lockStage < 1) {
                lock.allowance += 2000000;
                lock.lockStage = 1;
            }
        }else if(firstListingDate + 60 days >= block.timestamp && firstListingDate + 90 days < block.timestamp){
            if(lock.lockStage == 1){
                lock.allowance += 2000000;
                lock.lockStage = 2;
            }
        }else if(firstListingDate + 90 days >= block.timestamp && firstListingDate + 120 days < block.timestamp){
            if(lock.lockStage == 2){
                lock.allowance += 2000000;
                lock.lockStage = 3;
            }
        }else if(firstListingDate + 120 days >= block.timestamp && firstListingDate + 150 days < block.timestamp){
            if(lock.lockStage == 3){
                lock.allowance += 2000000;
                lock.lockStage = 4;
            }
        }else if(firstListingDate + 150 days >= block.timestamp && firstListingDate + 180 days < block.timestamp){
            if(lock.lockStage == 4){
                lock.allowance += 2000000;
                lock.lockStage = 5;
            }
        }else if(firstListingDate + 180 days >= block.timestamp && firstListingDate + 210 days < block.timestamp){
            if(lock.lockStage == 5){
                lock.allowance += 2000000;
                lock.lockStage = 6;
            }
        }else if(firstListingDate + 210 days >= block.timestamp && firstListingDate + 240 days < block.timestamp){
            if(lock.lockStage == 6){
                lock.allowance += 2000000;
                lock.lockStage = 7;
            }
        }else if(firstListingDate + 240 days >= block.timestamp && firstListingDate + 270 days < block.timestamp){
            if(lock.lockStage == 7){
                lock.allowance += 2000000;
                lock.lockStage = 8;
            }
        }else if(firstListingDate + 270 days >= block.timestamp && firstListingDate + 300 days < block.timestamp){
            if(lock.lockStage == 9){
                lock.allowance += 2000000;
                lock.lockStage = 10;
            }
        }else if(firstListingDate + 300 days >= block.timestamp){
            if(lock.lockStage == 10){
                lock.allowance += 2000000;
                lock.lockStage = 11;
            }
        }
        return true;
    }

    // function transfer(address _to, uint256 _value) canTransfer() investorChecks(_value) public override returns (bool success) {
    //     super.transfer(_to,_value);
    //     return true;
    // }

}