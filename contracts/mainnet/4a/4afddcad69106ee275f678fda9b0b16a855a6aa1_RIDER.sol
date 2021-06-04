/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity ^0.5.8;

/*
 * 컨트랙트 개요
 * 1. 목적
 *  메인넷 운영이 시작되기 전까지 한시적인 운영을 목적으로 하고 있다.
 *  메인넷이 운영되면 컨트랙트의 거래는 모두 중단되며, 메인넷 코인트로 전환을 시작하며,
 *  전환 절차를 간단하게 수행할 수 있으며, 블록체인 내 기록을 통해 신뢰도를 얻을 수 있도록 설계 되었다.
 * 2. 용어 설명
 *  Owner : 컨트랙트를 생성한 컨트랙트의 주인
 *  Delegator : Owner의 Private Key를 매번 사용하기에는 보안적인 이슈가 발생할 수 있기 때문에 도입된
 *              일부 Owner 권한을 실행할 수 있도록 임명한 대행자
 *              특히, 컨트랙트의 거래가 중단된 상태에서 Delegator만 실행할 수 있는 전용 함수를 실행하여
 *              컨트랙트의 토큰을 회수하고, 메인넷의 코인으로 전환해주는 핵심적인 기능을 수행
 *  Holder : 토큰을 보유할 수 있는 Address를 가지고 있는 계정
 * 3. 운용
 *  3.1. TokenContainer Structure
 *   3.1.1 Charge Amount
 *    Charge Amount는 Holder가 구매하여 충전한 토큰량입니다.
 *    Owner의 경우에는 컨트랙트 전체에 충전된 토큰량. 즉, Total Supply와 같습니다.
 *   3.1.2 Balance
 *    ERC20의 Balance와 같습니다.
 */
/*
 * Contract Overview 
 * 1. Purpose
 *  It is intended to operate for a limited time until mainnet launch.
 *  When the mainnet is launched, all transactions of the contract will be suspended from that day on forward and will initiate the token swap to the mainnet.
 * 2. Key Definitions
 *  Owner : An entity from which smart contract is created
 *  Delegator : The appointed agent is created to prevent from using the contract owner's private key for every transaction made, since it can cause a serious security issue.  
 *              In particular, it performs core functons at the time of the token swap event, such as executing a dedicated, Delegator-specific function while contract transaction is under suspension and
 *              withdraw contract's tokens. 
 *  Holder : An account in which tokens can be stored (also referrs to all users of the contract: Owner, Delegator, Spender, ICO buyers, ect.)
 * 3. Operation
 *  3.1. TokenContainer Structure
 *   3.1.1 Charge Amount
 *    Charge Amount is the charged token amount purcahsed by Holder.
 *    In case for the Owner, the total charged amount in the contract equates to the Total Supply.
 *   3.1.2 Balance
 *     Similiar to the ERC20 Balance.
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
}

/*
 * Owner의 권한 중 일부를 대신 행사할 수 있도록 대행자를 지정/해제 할 수 있는 인터페이스를 정의하고 있다.
 */
 /*
 * It defines an interface where the Owner can appoint / dismiss an agent that can partially excercize privileges in lieu of the Owner's 
 */
contract Delegable is Ownable {
    address private _delegator;
    
    event DelegateAppointed(address indexed previousDelegator, address indexed newDelegator);
    
    constructor () internal {
        _delegator = address(0);
    }
    
    /*
     * delegator를 가져옴
     */
    /*
     * Call-up Delegator
     */
    function delegator() public view returns (address) {
        return _delegator;
    }
    
    /*
     * delegator만 실행 가능하도록 지정하는 접근 제한
     */
    /*
     * Access restriction in which only appointed delegator is executable
     */
    modifier onlyDelegator() {
        require(isDelegator());
        _;
    }
    
    /*
     * owner 또는 delegator가 실행 가능하도록 지정하는 접근 제한
     */
    /*
     * Access restriction in which only appointed delegator or Owner are executable
     */
    modifier ownerOrDelegator() {
        require(isOwner() || isDelegator());
        _;
    }
    
    function isDelegator() public view returns (bool) {
        return msg.sender == _delegator;
    }
    
    /*
     * delegator를 임명
     */
    /*
     * Appoint the delegator
     */
    function appointDelegator(address delegator_) public onlyOwner returns (bool) {
        require(delegator_ != address(0));
        require(delegator_ != owner());
        return _appointDelegator(delegator_);
    }
    
    /*
     * 지정된 delegator를 해임
     */
    /*
     * Dimiss the appointed delegator
     */
    function dissmissDelegator() public onlyOwner returns (bool) {
        require(_delegator != address(0));
        return _appointDelegator(address(0));
    }
    
    /*
     * delegator를 변경하는 내부 함수
     */
    /*
     * An internal function that allows delegator changes 
     */
    function _appointDelegator(address delegator_) private returns (bool) {
        require(_delegator != delegator_);
        emit DelegateAppointed(_delegator, delegator_);
        _delegator = delegator_;
        return true;
    }
}

/*
 * ERC20의 기본 인터페이스는 유지하여 일반적인 토큰 전송이 가능하면서,
 * 일부 추가 관리 기능을 구현하기 위한 Struct 및 함수가 추가되어 있습니다.
 */
/*
 * The basic interface of ERC20 is remained untouched therefore basic functions like token transactions will be available. 
 * On top of that, Structs and functions have been added to implement some additional management functions.
 */
contract ERC20Like is IERC20, Delegable {
    using SafeMath for uint256;

    uint256 internal _totalSupply;  // 총 발행량 // Total Supply
    bool isLock = false;  // 계약 잠금 플래그 // Contract Lock Flag

    /*
     * 토큰 정보(충전량, 해금량, 가용잔액) 및 Spender 정보를 저장하는 구조체
     */
    /*
     * Structure that stores token information (charge, unlock, balance) as well as Spender information
     */
    struct TokenContainer {
        uint256 balance;  // 가용잔액 // available balance
        mapping (address => uint256) allowed; // Spender
    }

    mapping (address => TokenContainer) internal _tokenContainers;
    
    // 총 발행량 
    // Total token supply 
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // 가용잔액 가져오기
    // Call-up available balance
    function balanceOf(address holder) public view returns (uint256) {
        return _tokenContainers[holder].balance;
    }

    // Spender의 남은 잔액 가져오기
    // Call-up Spender's remaining balance
    function allowance(address holder, address spender) public view returns (uint256) {
        return _tokenContainers[holder].allowed[spender];
    }

    // 토큰송금
    // Transfer token
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    // Spender 지정 및 금액 지정
    // Appoint a Spender and set an amount 
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    
    function approveDelegator(address spender, uint256 value) public onlyDelegator returns (bool) {
        require(msg.sender == delegator());
        _approve(owner(), spender, value);
        return true;
    }

    // Spender 토큰송금
    // Transfer token via Spender 
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _tokenContainers[from].allowed[msg.sender].sub(value));
        return true;
    }
    
    // delegator인 경우에는 owner의 잔액을 대신 보낼 수 있음.
    function transferDelegator(address to, uint256 value) public onlyDelegator returns (bool) {
        require(msg.sender == delegator());
        _transfer(owner(), to, value);
        return true;
    }

    // Spender가 할당 받은 양 증가
    // Increase a Spender amount alloted by the Owner/Delegator
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(!isLock);
        uint256 value = _tokenContainers[msg.sender].allowed[spender].add(addedValue);
        _approve(msg.sender, spender, value);
        return true;
    }
    
    function increaseAllowanceDelegator(address spender, uint256 addedValue) public onlyDelegator returns (bool) {
        require(msg.sender == delegator());
        require(!isLock);
        uint256 value = _tokenContainers[owner()].allowed[spender].add(addedValue);
        _approve(owner(), spender, value);
        return true;
    }

    // Spender가 할당 받은 양 감소
    // Decrease a Spender amount alloted by the Owner/Delegator
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(!isLock);
        // 기존에 할당된 금액의 잔액보다 더 많은 금액을 줄이려고 하는 경우 할당액이 0이 되도록 처리
        //// If you reduce more than the alloted amount in the balance, we made sure the alloted amount is set to zero instead of minus
        if (_tokenContainers[msg.sender].allowed[spender] < subtractedValue) {
            subtractedValue = _tokenContainers[msg.sender].allowed[spender];
        }
        
        uint256 value = _tokenContainers[msg.sender].allowed[spender].sub(subtractedValue);
        _approve(msg.sender, spender, value);
        return true;
    }
    
    function decreaseAllowanceDelegator(address spender, uint256 subtractedValue) public onlyDelegator returns (bool) {
        require(msg.sender == delegator());
        require(!isLock);
        // 기존에 할당된 금액의 잔액보다 더 많은 금액을 줄이려고 하는 경우 할당액이 0이 되도록 처리
        //// If you reduce more than the alloted amount in the balance, we made sure the alloted amount is set to zero instead of minus
        if (_tokenContainers[owner()].allowed[spender] < subtractedValue) {
            subtractedValue = _tokenContainers[owner()].allowed[spender];
        }
        
        uint256 value = _tokenContainers[owner()].allowed[spender].sub(subtractedValue);
        _approve(owner(), spender, value);
        return true;
    }

    // 토큰송금 내부 실행 함수 
    // An internal execution function for troken transfer
    function _transfer(address from, address to, uint256 value) private {
        require(!isLock);
        // 3.1. Known vulnerabilities of ERC-20 token
        // 현재 컨트랙트로는 송금할 수 없도록 예외 처리 // Exceptions were added to not allow deposits to be made in the current contract . 
        require(to != address(this));
        require(to != address(0));

        _tokenContainers[from].balance = _tokenContainers[from].balance.sub(value);
        _tokenContainers[to].balance = _tokenContainers[to].balance.add(value);
        emit Transfer(from, to, value);
    }

    // Spender 지정 내부 실행 함수
    // Internal execution function for assigning a Spender
    function _approve(address holder, address spender, uint256 value) private {
        require(!isLock);
        require(spender != address(0));
        require(holder != address(0));

        _tokenContainers[holder].allowed[spender] = value;
        emit Approval(holder, spender, value);
    }

    // 전체 유통량 - Owner의 unlockAmount
    // Total circulation supply, or the unlockAmount of the Owner's
    function circulationAmount() external view returns (uint256) {
        return _totalSupply.sub(_tokenContainers[owner()].balance);
    }

    /*
     * 계약 잠금
     * 계약이 잠기면 컨트랙트의 거래가 중단된 상태가 되며,
     * 거래가 중단된 상태에서는 Owner와 Delegator를 포함한 모든 Holder는 거래를 할 수 없게 된다.
     */
    /*
     * Contract lock
     * If the contract is locked, all transactions will be suspended.
     * All Holders including Owner and Delegator will not be able to make transaction during suspension.
     */
    function lock() external onlyOwner returns (bool) {
        isLock = true;
        return isLock;
    }

    /*
     * 계약 잠금 해제
     * 잠긴 계약을 해제할 때 사용된다.
     */
    /*
     * Release contract lock
     * The function is used to revert a locked contract to a normal state. 
     */
    function unlock() external onlyOwner returns (bool) {
        isLock = false;
        return isLock;
    }
}

contract RIDER is ERC20Like {
    string public constant name = "RIDER";
    string public constant symbol = "RDR";
    uint256 public constant decimals = 18;
    
    event CreateToken(address indexed c_owner, string c_name, string c_symbol, uint256 c_totalSupply);

    constructor () public {
        _totalSupply = 3000000000 * (10 ** decimals);
        _tokenContainers[msg.sender].balance = _totalSupply;
        emit CreateToken(msg.sender, name, symbol, _tokenContainers[msg.sender].balance);
    }
}