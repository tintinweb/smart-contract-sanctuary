// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./owner.sol";

contract Payments  is Ownable {
    using SafeMath for uint256;
    
    string public name;
    address public PoS_Contract_Address;
    
    
    constructor (
        string memory _name,
        address  _address
    ) {
        name = _name;
        PoS_Contract_Address = _address;
    }
    
    modifier onlyPoS() {
        require(msg.sender == PoS_Contract_Address);
        _;
    }
    
    function changePoS(address _new_address) onlyOwner public  {
        PoS_Contract_Address = _new_address;
        emit ChangePoSContract(_new_address);
    }
    
    event ChangePoSContract(
        address indexed PoS_Contract_Address
    );
    
    event _localTransferFrom(
            address indexed _token,
            address indexed _from,
            address indexed _to,
            uint _value);
    
    event _registerToken(
            address indexed _token,
            uint8 indexed _id
        );
    
    mapping (address => 
        mapping (address => uint)
    ) public balances;
    
    uint8 tokensCount = 0;
    address[] knowableTokens;
    
    function registerToken(address _token) private {
        tokensCount++;
        knowableTokens.push(_token);
        emit _registerToken(_token, tokensCount-1); 
        
    }
    
    function addBalance(address _token, address _address, uint _balance) private {
        balances[_token][_address] = balances[_token][_address].add(_balance);
    }
    
    function getBalance(address _token, address _address) public view returns (uint result) {
        return balances[_token][_address];
    }
    
    function localTransferFrom(address _token, address _from, address _to, uint _amount) onlyPoS public {
        require (balances[_token][_from]  >= _amount);
        require (0  <  _amount);
        
        balances[_token][_from] = balances[_token][_from].sub(_amount);
        balances[_token][_to] = balances[_token][_to].add(_amount);
        
        emit _localTransferFrom(_token, _from, _to, _amount);
    }
    
    function depositToLocal(address _user_address, address _token, uint _amount) onlyPoS public {
        require (_amount > 0);
        
        bool founded = false;
        
        for (uint8 i = 0; i < tokensCount; i++) {
            if (knowableTokens[i] == _token) {
                founded = true;
                break;
            }
        }

        if (!founded) registerToken(_token);
        
        IERC20 tok = IERC20(_token);
        tok.transferFrom(_user_address, address(this), _amount);
        addBalance(_token, _user_address, _amount);
    }
    
     /**
            TODO:
                - add vesting/unlockable balance
     **/
    function closeDeposit(address _user_address, address _token) onlyPoS public {
       
        
        IERC20 tok = IERC20(_token);
        tok.transfer(_user_address, balances[_token][_user_address]);
        balances[_token][_user_address] = 0;
        
    }
}