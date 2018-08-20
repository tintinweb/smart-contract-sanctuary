pragma solidity ^0.4.22;
/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2018 Hexlant, Inc.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 *
 *
 * Open Source License Announcement
 * This smart contract code contains copyrighted source code under MIT License.
 *  - Copyright (c) 2016 Smart Contract Solutions, Inc.
 *    https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/LICENSE
 *
 * 
 * Contact Us : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="8deee2e3f9eceef9cde5e8f5e1ece3f9a3eee2e0">[email&#160;protected]</a>
 * Website    : http://hexlant.com
 * Medium Blog: https://medium.com/hexlant
 */

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;       
    }       

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyNewOwner() {
        require(msg.sender != address(0));
        require(msg.sender == newOwner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function acceptOwnership() public onlyNewOwner returns(bool) {
        emit OwnershipTransferred(owner, newOwner);        
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; 
}


contract SyncoToken is ERC20, Ownable, Pausable {

    using SafeMath for uint256;

    struct LockupInfo {
        uint256 releaseTime;
        uint256 termOfRound;
        uint256 unlockAmountPerRound;        
        uint256 lockupBalance;
    }

    string public name;
    string public symbol;
    uint8 constant public decimals =18;
    uint256 internal initialSupply;
    uint256 internal totalSupply_;

    mapping(address => uint256) internal balances;
    mapping(address => bool) internal locks;
    mapping(address => bool) public frozen;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => LockupInfo[]) internal lockupInfo;

    event Lock(address indexed holder, uint256 value);
    event Unlock(address indexed holder, uint256 value);
    event Burn(address indexed owner, uint256 value);
    event Mint(uint256 value);
    event Freeze(address indexed holder);
    event Unfreeze(address indexed holder);

    modifier notFrozen(address _holder) {
        require(!frozen[_holder]);
        _;
    }

    constructor() public {
        name = "SYNCO Token";
        symbol = "SYNCO";
        initialSupply = 13000000000;
        totalSupply_ = initialSupply * 10 ** uint(decimals);
        balances[owner] = totalSupply_;
        emit Transfer(address(0), owner, totalSupply_);
    }

    function () public payable {
        revert();
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused notFrozen(msg.sender) returns (bool) {
        if (locks[msg.sender]) {
            autoUnlock(msg.sender);            
        }
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _holder) public view returns (uint256 balance) {
        uint256 lockedBalance = 0;
        if(locks[_holder]) {
            for(uint256 idx = 0; idx < lockupInfo[_holder].length ; idx++ ) {
                lockedBalance = lockedBalance.add(lockupInfo[_holder][idx].lockupBalance);
            }
        }
        return balances[_holder] + lockedBalance;
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused notFrozen(_from)returns (bool) {
        if (locks[_from]) {
            autoUnlock(_from);            
        }
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        require(isContract(_spender));
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function allowance(address _holder, address _spender) public view returns (uint256) {
        return allowed[_holder][_spender];
    }

    function lock(address _holder, uint256 _amount, uint256 _releaseStart, uint256 _termOfRound, uint256 _releaseRate) public onlyOwner returns (bool) {
        require(balances[_holder] >= _amount);
        if(_termOfRound==0 ) {
            _termOfRound = 1;
        }
        balances[_holder] = balances[_holder].sub(_amount);
        lockupInfo[_holder].push(
            LockupInfo(_releaseStart, _termOfRound, _amount.div(100).mul(_releaseRate), _amount)
        );

        locks[_holder] = true;

        emit Lock(_holder, _amount);

        return true;
    }

    function unlock(address _holder, uint256 _idx) public onlyOwner returns (bool) {
        require(locks[_holder]);
        require(_idx < lockupInfo[_holder].length);
        LockupInfo storage lockupinfo = lockupInfo[_holder][_idx];
        uint256 releaseAmount = lockupinfo.lockupBalance;

        delete lockupInfo[_holder][_idx];
        lockupInfo[_holder][_idx] = lockupInfo[_holder][lockupInfo[_holder].length.sub(1)];
        lockupInfo[_holder].length -=1;
        if(lockupInfo[_holder].length == 0) {
            locks[_holder] = false;
        }

        emit Unlock(_holder, releaseAmount);
        balances[_holder] = balances[_holder].add(releaseAmount);

        return true;
    }

    function freezeAccount(address _holder) public onlyOwner returns (bool) {
        require(!frozen[_holder]);
        frozen[_holder] = true;
        emit Freeze(_holder);
        return true;
    }

    function unfreezeAccount(address _holder) public onlyOwner returns (bool) {
        require(frozen[_holder]);
        frozen[_holder] = false;
        emit Unfreeze(_holder);
        return true;
    }

    function getNowTime() public view returns(uint256) {
        return now;
    }

    function showLockState(address _holder, uint256 _idx) public view returns (bool, uint256, uint256, uint256, uint256, uint256) {
        if(locks[_holder]) {
            return (
                locks[_holder], 
                lockupInfo[_holder].length, 
                lockupInfo[_holder][_idx].lockupBalance, 
                lockupInfo[_holder][_idx].releaseTime, 
                lockupInfo[_holder][_idx].termOfRound, 
                lockupInfo[_holder][_idx].unlockAmountPerRound
            );
        } else {
            return (
                locks[_holder], 
                lockupInfo[_holder].length, 
                0,0,0,0
            );

        }        
    }
    
    function distribute(address _to, uint256 _value) public onlyOwner returns (bool) {
        require(_to != address(0));
        require(_value <= balances[owner]);

        balances[owner] = balances[owner].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(owner, _to, _value);
        return true;
    }

    function distributeWithLockup(address _to, uint256 _value, uint256 _releaseStart, uint256 _termOfRound, uint256 _releaseRate) public onlyOwner returns (bool) {
        distribute(_to, _value);
        lock(_to, _value, _releaseStart, _termOfRound, _releaseRate);
        return true;
    }

    function claimToken(ERC20 token, address _to, uint256 _value) public onlyOwner returns (bool) {
        token.transfer(_to, _value);
        return true;
    }

    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        return true;
    }

    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly{size := extcodesize(addr)}
        return size > 0;
    }

    function autoUnlock(address _holder) internal returns (bool) {

        for(uint256 idx =0; idx < lockupInfo[_holder].length ; idx++ ) {
            if(locks[_holder]==false) {
                return true;
            }
            if (lockupInfo[_holder][idx].releaseTime <= now) {
                // If lockupinfo was deleted, loop restart at same position.
                if( releaseTimeLock(_holder, idx) ) {
                    idx -=1;
                }
            }
        }
        return true;
    }

    function releaseTimeLock(address _holder, uint256 _idx) internal returns(bool) {
        require(locks[_holder]);
        require(_idx < lockupInfo[_holder].length);

        // If lock status of holder is finished, delete lockup info. 
        LockupInfo storage info = lockupInfo[_holder][_idx];
        uint256 releaseAmount = info.unlockAmountPerRound;
        uint256 sinceFrom = now.sub(info.releaseTime);
        uint256 sinceRound = sinceFrom.div(info.termOfRound);
        releaseAmount = releaseAmount.add( sinceRound.mul(info.unlockAmountPerRound) );

        if(releaseAmount >= info.lockupBalance) {            
            releaseAmount = info.lockupBalance;

            delete lockupInfo[_holder][_idx];
            lockupInfo[_holder][_idx] = lockupInfo[_holder][lockupInfo[_holder].length.sub(1)];
            lockupInfo[_holder].length -=1;

            if(lockupInfo[_holder].length == 0) {
                locks[_holder] = false;
            }
            emit Unlock(_holder, releaseAmount);
            balances[_holder] = balances[_holder].add(releaseAmount);
            return true;
        } else {
            lockupInfo[_holder][_idx].releaseTime = lockupInfo[_holder][_idx].releaseTime.add( sinceRound.add(1).mul(info.termOfRound) );
            lockupInfo[_holder][_idx].lockupBalance = lockupInfo[_holder][_idx].lockupBalance.sub(releaseAmount);
            emit Unlock(_holder, releaseAmount);
            balances[_holder] = balances[_holder].add(releaseAmount);
            return false;
        }
    }


}