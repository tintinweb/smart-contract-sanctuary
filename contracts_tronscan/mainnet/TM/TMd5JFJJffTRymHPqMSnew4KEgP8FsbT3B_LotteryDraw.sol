//SourceUnit: LotteryDraw.sol

pragma solidity ^0.4.23;


interface ITRC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function transferTo(address to, uint value) external;

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Ownable {

    // public variables
    address public owner;

    // internal variables

    // events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // public functions
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // internal functions
}
    
contract Pausable is Ownable {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
    
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        else if (x <= 3) return 1;
        uint256 z = div(add(x, 1), 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = div(add(div(x, z), z), 2);
        }
    }
}

contract LotteryDraw is Pausable {
    using SafeMath for uint256;
    mapping(bytes3 => ITRC20) public tokens;
    uint256 public decimal = 6;
    mapping(bytes3 => uint256) public tokenScores;
    mapping(bytes3 => uint256) public tokenRates;
    uint256[12] public recentScores = [54600,78000,45400,9600,108900,105800,44500,101400,37100,308200,118800,64000];
    uint256 public recentScoresIndex = 0;
    address public beneficiary;
    
    mapping(address => uint256) public times;
    address[] public users;
    uint256 public totalTimes = 0;
    
    uint256 public totalAmount = 0;
    
    event Lotterydx(address indexed addr, uint256 dci, uint256 dli, uint256 dln, uint256 dti, uint256 dxa, uint256 dxn, uint256 dyi, uint256 dzg, uint256 amount, uint256 score);
    event Lotteryga(address indexed addr, uint256 dci, uint256 dli, uint256 dln, uint256 dti, uint256 dxa, uint256 dxn, uint256 dyi, uint256 dzg, uint256 times);
    event Lotterygr(address indexed addr, uint256 times, uint256 amount);
    
    /*
     * only human is allowed to call this contract
     */
    modifier isHuman() {
        require(msg.sender == tx.origin);
        _;
    }
    
    constructor() public {
    }

    function init(address dci, address dli, address dln, address dti, address dxa, address dxn, address dyi, address dzg, address ff, address bene) public onlyOwner {
        require(dci != address(0));
        require(dli != address(0));
        require(dln != address(0));
        require(dti != address(0));
        require(dxa != address(0));
        require(dxn != address(0));
        require(dyi != address(0));
        require(dzg != address(0));
        require(ff != address(0));
        require(bene != address(0));
        tokens["DCI"] = ITRC20(dci);
        tokens["DLI"] = ITRC20(dli);
        tokens["DLN"] = ITRC20(dln);
        tokens["DTI"] = ITRC20(dti);
        tokens["DXA"] = ITRC20(dxa);
        tokens["DXN"] = ITRC20(dxn);
        tokens["DYI"] = ITRC20(dyi);
        tokens["DZG"] = ITRC20(dzg);
        tokens["FF"] = ITRC20(ff);
        beneficiary = bene;
        tokenScores["DXA"] = 410;
        tokenScores["DTI"] = 310;
        tokenScores["DZG"] = 13;
        tokenScores["DXN"] = 7;
        tokenScores["DLI"] = 5;
        tokenScores["DYI"] = 3;
        tokenScores["DLN"] = 2;
        tokenScores["DCI"] = 1;
        tokenRates["DXA"] = 40;
        tokenRates["DTI"] = 30;
        tokenRates["DZG"] = 20;
        tokenRates["DXN"] = 10;
        tokenRates["DLI"] = 4;
        tokenRates["DYI"] = 2;
        tokenRates["DLN"] = 1;
        tokenRates["DCI"] = 0;
    }
    
    function getRandom(uint256 hash) internal pure returns(uint256) {
        uint256 d = hash;
        uint256 m = 0;
        uint256 sum = 0;
        for (int i = 0; i < 64; i++) {
            m = d.mod(16);
            if (m > 9) {
                m = m.sub(9);
            }
            sum = sum.add(m);
            d = d.div(16);
        }
        uint256 v = 100;
        if (sum >= v) {
            sum = sum.sub(v).div(2);
        } else  {
            sum = v.sub(sum).div(2);
        }
        return sum;
    }
    
    function lottery(uint256 score, uint256 rate) internal returns(uint256, uint256) {
        require(score >= 8 && score <= 3280);
        require(rate >= 0 && rate <= 320);
        uint256 amount = 0;
        uint256 hash = uint256(blockhash(block.number-1));
        uint256 rscore = getRandom(hash).mul(score).mul(rate.add(100));
        uint256 avg = 0;
        for (uint256 i = 0; i < recentScores.length; i++) {
            avg = avg.add(recentScores[i]);
        }
        avg = avg.div(recentScores.length);
        uint256 radio = rscore.div(avg);
        uint256 pct = 0;
        if (radio >= 800) {
            pct = 3000;
        } else if (radio >= 500) {
            pct = 1500;
        } else if (radio >= 300) {
            pct = 500;
        } else if (radio >= 200) {
            pct = 100;
        } else if (radio >= 100) {
            pct = 50;
        } else if (radio >= 50) {
            pct = 20;
        } else if (radio >= 20) {
            pct = 10;
        } else if (radio >= 10) {
            pct = 8;
        } else if (radio >= 1) {
            pct = 5;
        } else {
            pct = 2;
        }
        amount = address(this).balance.mul(pct).div(10000);
        msg.sender.transfer(amount);
        recentScores[recentScoresIndex] = rscore;
        recentScoresIndex++;
        if (recentScoresIndex >= recentScores.length) {
            recentScoresIndex = 0;
        }
        return (amount, rscore);
    }
    
    function lotterydx(uint256 dci, uint256 dli, uint256 dln, uint256 dti, uint256 dxa, uint256 dxn, uint256 dyi, uint256 dzg) public isHuman whenNotPaused returns(uint256) {
        uint256 amount = dci.add(dli).add(dln);
        amount = amount.add(dti).add(dxa).add(dxn);
        amount = amount.add(dyi).add(dzg);
        require(amount == 8);
        amount = 0;
        uint256 rate = 0;
        if (dci > 0) {
            amount = amount.add(tokenScores["DCI"].mul(dci));
            rate = rate.add(tokenRates["DCI"].mul(dci));
            tokens["DCI"].transferTo(beneficiary, dci.mul(10 ** decimal));
        }
        if (dli > 0) {
            amount = amount.add(tokenScores["DLI"].mul(dli));
            rate = rate.add(tokenRates["DLI"].mul(dli));
            tokens["DLI"].transferTo(beneficiary, dli.mul(10 ** decimal));
        }
        if (dln > 0) {
            amount = amount.add(tokenScores["DLN"].mul(dln));
            rate = rate.add(tokenRates["DLN"].mul(dln));
            tokens["DLN"].transferTo(beneficiary, dln.mul(10 ** decimal));
        }
        if (dti > 0) {
            amount = amount.add(tokenScores["DTI"].mul(dti));
            rate = rate.add(tokenRates["DTI"].mul(dti));
            tokens["DTI"].transferTo(beneficiary, dti.mul(10 ** decimal));
        }
        if (dxa > 0) {
            amount = amount.add(tokenScores["DXA"].mul(dxa));
            rate = rate.add(tokenRates["DXA"].mul(dxa));
            tokens["DXA"].transferTo(beneficiary, dxa.mul(10 ** decimal));
        }
        if (dxn > 0) {
            amount = amount.add(tokenScores["DXN"].mul(dxn));
            rate = rate.add(tokenRates["DXN"].mul(dxn));
            tokens["DXN"].transferTo(beneficiary, dxn.mul(10 ** decimal));
        }
        if (dyi > 0) {
            amount = amount.add(tokenScores["DYI"].mul(dyi));
            rate = rate.add(tokenRates["DYI"].mul(dyi));
            tokens["DYI"].transferTo(beneficiary, dyi.mul(10 ** decimal));
        }
        if (dzg > 0) {
            amount = amount.add(tokenScores["DZG"].mul(dzg));
            rate = rate.add(tokenRates["DZG"].mul(dzg));
            tokens["DZG"].transferTo(beneficiary, dzg.mul(10 ** decimal));
        }
        (amount, rate) = lottery(amount, rate);
        totalAmount = totalAmount.add(amount);
        emit Lotterydx(msg.sender, dci, dli, dln, dti, dxa, dxn, dyi, dzg, amount, rate);
        return amount;
    }
    
    function lotteryga(uint256 dci, uint256 dli, uint256 dln, uint256 dti, uint256 dxa, uint256 dxn, uint256 dyi, uint256 dzg) public isHuman whenNotPaused {
        require(dci == 1 && dli == 1 && dln == 1 && dti == 1 && dxa == 1 && dxn == 1 && dyi == 1 && dzg == 1);
        tokens["DXA"].transferTo(beneficiary, dci.mul(10 ** decimal));
        tokens["DTI"].transferTo(beneficiary, dli.mul(10 ** decimal));
        tokens["DZG"].transferTo(beneficiary, dln.mul(10 ** decimal));
        tokens["DXN"].transferTo(beneficiary, dti.mul(10 ** decimal));
        tokens["DLI"].transferTo(beneficiary, dxa.mul(10 ** decimal));
        tokens["DYI"].transferTo(beneficiary, dxn.mul(10 ** decimal));
        tokens["DLN"].transferTo(beneficiary, dyi.mul(10 ** decimal));
        tokens["DCI"].transferTo(beneficiary, dzg.mul(10 ** decimal));
        if (times[msg.sender] > 0) {
            times[msg.sender] = times[msg.sender].add(1);
        } else {
            times[msg.sender] = 1;
            users.push(msg.sender);
        }
        totalTimes = totalTimes.add(1);
        emit Lotteryga(msg.sender, dci, dli, dln, dti, dxa, dxn, dyi, dzg, times[msg.sender]);
    }
    
    function lotterygr() public onlyOwner whenNotPaused {
        require(users.length > 0 && totalTimes > 0);
        require(address(this).balance > 0);
        uint256 per = address(this).balance.mul(3).div(10).div(totalTimes);
        for (uint256 i = 0; i < users.length; i++) {
            uint256 tms = times[users[i]];
            uint256 amount = per.mul(tms);
            times[users[i]] = 0;
            users[i].transfer(amount);
            totalAmount = totalAmount.add(amount);
            emit Lotterygr(users[i], tms, amount);
        }
        users.length = 0;
        totalTimes = 0;
    }
    
    function() public payable {
        require(address(msg.sender) != address(0) && address(msg.sender) != address(this));
    }
    
    function balance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function totalAmount() public view returns(uint256) {
        return totalAmount;
    }
    
    function withdraw() public onlyOwner {
        require(address(this).balance > 0);
        beneficiary.transfer(address(this).balance);
    }
}