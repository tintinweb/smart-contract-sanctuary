/**
 *Submitted for verification at polygonscan.com on 2022-01-08
*/

// SPDX-License-Identifier: Apache-2.0
// ERC20 with Voronoi

pragma solidity ^0.8.11;

contract VoronoiToken {
    string public constant name     = "CryptoDev Coin";  					// -> Unique compared to other CryptoDevTech tokens
    string public constant symbol   = "CRYPTODEV";					// -> Unique compared to other CryptoDevTech tokens
    uint8  public constant decimals = 0;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event major_impact_call(bool value);                                                // Event when a Major Impact Function is called
    event minor_impact_call(bool value);                                                // Event when a Minor Impact Function is called
    event function_unlock(uint256 value);                                               // Unlock event, when a function gets unlocked, unit256 -> func ID

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    mapping (uint256 => address) internal unlocker_ids;                                  // Needs to be in sync with the unlocker_ids, max 10
    mapping (uint256 => uint256) internal unlocker_stakes;                               // Address to threshold amount (single account can have multiple)

    uint256 private totalSupply_ = 1000000000;					 // -> Unique compared to other CryptoDevTech tokens
    address private admin;
    uint256 private _voronoi_count;
    uint256 private threshold;
    uint256 private _voronoi_last_time;

    bool private _paused;

    constructor() {
        admin = msg.sender;
        balances[msg.sender] = totalSupply_;
        _paused = false;
        _voronoi_count = 0;
        threshold = 3;                                                                      // 3 Head Members need to vote for major action to be taken
        _voronoi_last_time = block.timestamp;
        unlocker_ids[0] = 0xf0e065065dF92e56f8C45e19E74370942AB21f95;                       // We define 10 Head Members accounts here
        unlocker_ids[1] = 0x1C43632e03c7832a8FA6F9144C585d4f0587Eb9B;
        unlocker_ids[2] = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
        unlocker_ids[3] = 0xA3726D9c6a7a0C255A649066ABF92d5F738BBec0;
        unlocker_ids[4] = 0xa1bAA6C66930a3FB9803726f41D5E4F855805028;
        unlocker_ids[5] = 0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C;
        unlocker_ids[6] = 0x5A350e936C3E2B518672761a345519cA66eE975a;
        unlocker_ids[7] = 0x4A829C93d88298E4398F1a6A4802d9a025AcD524;
        unlocker_ids[8] = 0x184313F91f4127DCC1F1c606103db1b6a8858CA8;
        unlocker_ids[9] = 0x266b2ccabb515D39bB394627211a0A83dd510D2b;
        unlocker_stakes[0] = 1;
        unlocker_stakes[1] = 1;
        unlocker_stakes[2] = 1;
        unlocker_stakes[3] = 1;
        unlocker_stakes[4] = 1;
        unlocker_stakes[5] = 1;
        unlocker_stakes[6] = 1;
        unlocker_stakes[7] = 1;
        unlocker_stakes[8] = 1;
        unlocker_stakes[9] = 1;
    }

    function voronoi_stake_up() external returns (bool success){
        emit minor_impact_call(true);
        require(msg.sender == unlocker_ids[0] ||
        msg.sender == unlocker_ids[1] ||
        msg.sender == unlocker_ids[2] ||
        msg.sender == unlocker_ids[3] ||
        msg.sender == unlocker_ids[4] || 
        msg.sender == unlocker_ids[5] || 
        msg.sender == unlocker_ids[6] || 
        msg.sender == unlocker_ids[7] || 
        msg.sender == unlocker_ids[8] || 
        msg.sender == unlocker_ids[9]);

        if (msg.sender == unlocker_ids[0]){                                         // Avoid loops.
            require(unlocker_stakes[0] == 1);
            unlocker_stakes[0] = 0;
        }
        else if (msg.sender == unlocker_ids[1]) {
            require(unlocker_stakes[1] == 1);
            unlocker_stakes[1] = 0;
        }
        else if (msg.sender == unlocker_ids[2]) {
            require(unlocker_stakes[2] == 1);
            unlocker_stakes[2] = 0;
        }
        else if (msg.sender == unlocker_ids[3]) {
            require(unlocker_stakes[3] == 1);
            unlocker_stakes[3] = 0;
        }
        else if (msg.sender == unlocker_ids[4]) {
            require(unlocker_stakes[4] == 1);
            unlocker_stakes[4] = 0;
        }
        else if (msg.sender == unlocker_ids[5]) {
        require(unlocker_stakes[5] == 1);
            unlocker_stakes[5] = 0;
        }
        else if (msg.sender == unlocker_ids[6]) {
        require(unlocker_stakes[6] == 1);
            unlocker_stakes[6] = 0;
        }
        else if (msg.sender == unlocker_ids[7]) {
            require(unlocker_stakes[7] == 1);
            unlocker_stakes[7] = 0;
        }
        else if (msg.sender == unlocker_ids[8]) {
            require(unlocker_stakes[8] == 1);
            unlocker_stakes[8] = 0;
        }
        else if (msg.sender == unlocker_ids[9]) {
            require(unlocker_stakes[9] == 1);
            unlocker_stakes[9] = 0;
        }
        _voronoi_count = _voronoi_count + 1;
        return true;
    }

    function vcheck_stake(uint256 _idToCheck) external view returns(uint256 success){
        return unlocker_stakes[_idToCheck];
    }

    function vcheck_count() external view returns(uint256 success){
        return _voronoi_count;
    }

    function v_reset() external returns (bool success){
        emit major_impact_call(true);
        require(msg.sender == unlocker_ids[0] ||
        msg.sender == unlocker_ids[1] ||
        msg.sender == unlocker_ids[2] ||
        msg.sender == unlocker_ids[3] ||
        msg.sender == unlocker_ids[4] || 
        msg.sender == unlocker_ids[5] || 
        msg.sender == unlocker_ids[6] || 
        msg.sender == unlocker_ids[7] || 
        msg.sender == unlocker_ids[8] || 
        msg.sender == unlocker_ids[9]);
        require(block.timestamp >= _voronoi_last_time + 1 minutes);                           // You can only do it once every hour to secure voting logic
        _voronoi_last_time = block.timestamp;
        _voronoi_count = 0;
        unlocker_stakes[0] = 1;
        unlocker_stakes[1] = 1;
        unlocker_stakes[2] = 1;
        unlocker_stakes[3] = 1;
        unlocker_stakes[4] = 1;
        unlocker_stakes[5] = 1;
        unlocker_stakes[6] = 1;
        unlocker_stakes[7] = 1;
        unlocker_stakes[8] = 1;
        unlocker_stakes[9] = 1;
        return true;
    }

    function unlocker_role_change(uint256 _id, address _new_unlocker) external returns (bool){
        emit major_impact_call(true);
        require(msg.sender == unlocker_ids[0] ||
        msg.sender == unlocker_ids[1] ||
        msg.sender == unlocker_ids[2] ||
        msg.sender == unlocker_ids[3] ||
        msg.sender == unlocker_ids[4] || 
        msg.sender == unlocker_ids[5] || 
        msg.sender == unlocker_ids[6] || 
        msg.sender == unlocker_ids[7] || 
        msg.sender == unlocker_ids[8] || 
        msg.sender == unlocker_ids[9]);
        require(_voronoi_count >= threshold);
        unlocker_ids[_id] = _new_unlocker;
        return true;
    }


    function pause() external returns (bool success) {
        emit major_impact_call(true);
        require(msg.sender == unlocker_ids[0] ||
        msg.sender == unlocker_ids[1] ||
        msg.sender == unlocker_ids[2] ||
        msg.sender == unlocker_ids[3] ||
        msg.sender == unlocker_ids[4] || 
        msg.sender == unlocker_ids[5] || 
        msg.sender == unlocker_ids[6] || 
        msg.sender == unlocker_ids[7] || 
        msg.sender == unlocker_ids[8] || 
        msg.sender == unlocker_ids[9]);
        emit major_impact_call(true);
        require(_voronoi_count >= threshold);
        _paused = true;
        return _paused;
    }

    function unpause() external returns (bool success) {
        emit major_impact_call(true);
        require(msg.sender == unlocker_ids[0] ||
        msg.sender == unlocker_ids[1] ||
        msg.sender == unlocker_ids[2] ||
        msg.sender == unlocker_ids[3] ||
        msg.sender == unlocker_ids[4] || 
        msg.sender == unlocker_ids[5] || 
        msg.sender == unlocker_ids[6] || 
        msg.sender == unlocker_ids[7] || 
        msg.sender == unlocker_ids[8] || 
        msg.sender == unlocker_ids[9]);
        emit major_impact_call(true);
        require(_voronoi_count >= threshold);
        _paused = false;
        return _paused;
    }

    function adminChange(address newAdmin) external returns (address to) {                  // Community head members can change admin if voted.
        emit major_impact_call(true);
        require(msg.sender == unlocker_ids[0] ||
        msg.sender == unlocker_ids[1] ||
        msg.sender == unlocker_ids[2] ||
        msg.sender == unlocker_ids[3] ||
        msg.sender == unlocker_ids[4] || 
        msg.sender == unlocker_ids[5] || 
        msg.sender == unlocker_ids[6] || 
        msg.sender == unlocker_ids[7] || 
        msg.sender == unlocker_ids[8] || 
        msg.sender == unlocker_ids[9]);
        emit major_impact_call(true);
        require(_voronoi_count >= threshold);
        admin = newAdmin;
        return newAdmin;
    }


    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        emit minor_impact_call(true);
        require(_paused == false);
        require(_value <= balances[msg.sender]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        emit minor_impact_call(true);
        require(_paused == false);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        emit minor_impact_call(true);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function adminWithdraw() external returns (bool success) {
        emit major_impact_call(true);
        require(msg.sender == admin, "Not authorized");
        require(_voronoi_count >= threshold);
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }

    fallback() external payable {}
    receive() external payable {}
}