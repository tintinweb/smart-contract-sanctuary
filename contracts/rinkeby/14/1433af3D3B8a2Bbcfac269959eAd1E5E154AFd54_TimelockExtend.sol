/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

pragma solidity ^0.5.0;


contract IERC20{
    string public symbol;
    string public name;
    uint256 public totalSupply;
    uint8 public decimals;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TimelockExtend {
    // using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;
    uint private _deployeTime;

    uint private part1Time = 300; // 86400 * 5
    uint private Part1Qty = 500000000000000000000; // 50000000000000000000000000
    bool private part1Statue = true;
    
    uint256 private releaseCount = 0; // 
    uint private releaseQty = 450000000000000000000; // 4500000; 4500000000000000000000000
    // uint private stepTime = 2592000; // month:2592000; day: 86400
    uint private stepTime = 300;

    constructor (IERC20 token, address beneficiary, uint256 releaseTime) public {
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime > block.timestamp, 'release time is before');
        _token = token;
        _beneficiary = beneficiary;
        _deployeTime = block.timestamp;
        _releaseTime = releaseTime;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return (_beneficiary);
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view returns (uint256,uint256) {
        return (_releaseTime, _deployeTime);
    }
    
    /**
     * @return the time when the tokens are released.
     */
    function getReleaseCount() public view returns (uint256) {
        return releaseCount;
    }
    
    /**
     * @return this contract balance
     */
    function balance() public view returns (uint) {
        
        return _token.balanceOf(address(this));
    }
    
    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function releasePartOne() public {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _deployeTime + part1Time, 'before release time');
        require(_token.balanceOf(address(this)) > 0, 'release done');
        require(part1Statue == true, 'release done');
        
        _token.transfer(_beneficiary, Part1Qty);
        
        part1Statue = false;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _releaseTime + (stepTime * releaseCount), 'before release time');
        
        uint thisBalance = _token.balanceOf(address(this));
        require(thisBalance > 0, 'release done');
        
        if (thisBalance>=releaseQty) {
        
            _token.transfer(_beneficiary, releaseQty);
        } else {
            
            _token.transfer(_beneficiary, thisBalance);
        }

        releaseCount++;
    }
}