/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

pragma solidity ^0.6.2;
// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

  
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
      

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC659 {
    function totalSupply( uint256 class, uint256 nonce) external view returns (uint256);
    function activeSupply( uint256 class, uint256 nonce) external view returns (uint256);
    function burnedSupply( uint256 class, uint256 nonce) external view returns (uint256);
    function redeemedSupply(  uint256 class, uint256 nonce) external  view  returns (uint256);
   
    function getNonceCreated(uint256 class) external view returns (uint256[] memory);
    function getClassCreated() external view returns (uint256[] memory);
    
    function balanceOf(address account, uint256 class, uint256 nonce) external view returns (uint256);
    function batchBalanceOf(address account, uint256 class) external view returns(uint256[] memory);
    
    function getBondSymbol(uint256 class) view external returns (string memory);
    function getBondInfo(uint256 class, uint256 nonce) external view returns (string memory BondSymbol, uint256 timestamp, uint256 info2, uint256 info3, uint256 info4, uint256 info5,uint256 info6);
    function bondIsRedeemable(uint256 class, uint256 nonce) external view returns (bool);
    
 
    function issueBond(address _to, uint256  class, uint256 _amount) external returns(bool);
    function redeemBond(address _from, uint256 class, uint256[] calldata nonce, uint256[] calldata _amount) external returns(bool);
    function transferBond(address _from, address _to, uint256[] calldata class, uint256[] calldata nonce, uint256[] calldata _amount) external returns(bool);
    function burnBond(address _from, uint256[] calldata class, uint256[] calldata nonce, uint256[] calldata _amount) external returns(bool);
    
    event eventIssueBond(address _operator, address _to, uint256 class, uint256 nonce, uint256 _amount); 
    event eventRedeemBond(address _operator, address _from, uint256 class, uint256 nonce, uint256 _amount);
    event eventBurnBond(address _operator, address _from, uint256 class, uint256 nonce, uint256 _amount);
    event eventTransferBond(address _operator, address _from, address _to, uint256 class, uint256 nonce, uint256 _amount);
}

interface ISigmoidBonds{
    function isActive(bool _contract_is_active) external returns (bool);
    function setGovernanceContract(address governance_address) external returns (bool);
    function setExchangeContract(address governance_address) external returns (bool);
    function setBankContract(address bank_address) external returns (bool);
    function setTokenContract(uint256 class, address contract_address) external returns (bool);
    function createBondClass(uint256 class, string calldata bond_symbol, uint256 Fibonacci_number, uint256 Fibonacci_epoch)external returns (bool);
}


contract ERC659data {
    mapping (address => mapping( uint256 =>mapping(uint256=> uint256))) public _balances;
    
    mapping (uint256 => mapping(uint256 => uint256)) public _activeSupply;
    
    mapping (uint256 => mapping(uint256 => uint256)) public _burnedSupply;
  
    mapping (uint256 => mapping(uint256 => uint256)) public _redeemedSupply;

    mapping (uint256 => address) public _bankAddress;
    
    mapping (uint256 => string) public _Symbol;
    
    mapping (uint256 => mapping(uint256=> mapping(uint256=> uint256))) public _info;

    mapping (uint256 => uint256)  public last_bond_nonce;
    
    mapping (uint256 => uint256[]) public _nonceCreated;
    
    uint256[] public _classCreated;
    
}

contract SigmoidBonds is IERC659, ISigmoidBonds, ERC659data{
    using SafeMath for uint256;
    
    bool public contract_is_active;
    address public governance_contract;
    address public exchange_contract;
    address public bank_contract;
    address public bond_contract;
    
    mapping (uint256 => uint256) public last_activeSupply;
    
    mapping (uint256 => uint256) public last_burnedSupply;
  
    mapping (uint256 => uint256) public last_redeemedSupply;
    
    
    mapping (uint256 => address) public token_contract;
  
    mapping (uint256 => uint256)  public last_bond_redeemed;
    mapping (uint256 => uint256)  public _Fibonacci_number;
    mapping (uint256 => uint256)  public _Fibonacci_epoch;
    mapping (uint256 => uint256)  public _genesis_nonce_time;

    constructor ( address governance_address) public {

        governance_contract=governance_address; 
        _classCreated=[0,1,2,3];
        
        _Symbol[0]="SASH-USD";
        _Fibonacci_number[0]=8;
        _Fibonacci_epoch[0]=8*60*60;
        _genesis_nonce_time[0]=0;
        
        _Symbol[1]="SGM-SASH";
        _Fibonacci_number[1]=8;
        _Fibonacci_epoch[1]=8*60*60;
        _genesis_nonce_time[1]=0;
        
        _Symbol[2]="SGM,SGM";
        _Fibonacci_number[2]=8;
        _Fibonacci_epoch[2]=8*60*60;
        _genesis_nonce_time[2]=0;
        
        _Symbol[3]="SASH,SGM";
        _Fibonacci_number[3]=8;
        _Fibonacci_epoch[3]=8*60*60;
        _genesis_nonce_time[3]=0;
        
    }
    
     function isActive(bool _contract_is_active) public override returns (bool){
         contract_is_active = _contract_is_active;
         return(contract_is_active);
         
     }
     
     function setGovernanceContract(address governance_address) public override returns (bool) {
        require(msg.sender==governance_contract, "ERC659: operator unauthorized");
        governance_contract = governance_address;
        return(true);
    }
    
    function setExchangeContract(address exchange_address) public override returns (bool) {
        require(msg.sender==governance_contract, "ERC659: operator unauthorized");
        exchange_contract = exchange_address;
        return(true);
    }
    
    function setBankContract(address bank_address) public override returns (bool) {
        require(msg.sender==governance_contract, "ERC659: operator unauthorized");
        bank_contract = bank_address;
        return(true);
    }
      
    function setTokenContract(uint256 class, address contract_address) public override returns (bool) {
        require(msg.sender==governance_contract, "ERC659: operator unauthorized");
        token_contract[class] = contract_address;
        return(true);
    }
    
    function getNonceCreated(uint256 class) public override view returns (uint256[] memory){
        return _nonceCreated[class];
    }
    
    function getClassCreated() public override view returns (uint256[] memory){
        return _classCreated;
    }
    
    function createBondClass(uint256 class, string memory bond_symbol, uint256 Fibonacci_number, uint256 Fibonacci_epoch)public override returns (bool) {
        require(msg.sender==governance_contract, "ERC659: operator unauthorized");
        _Symbol[class]=bond_symbol;
        _Fibonacci_number[class]=Fibonacci_number;
        _Fibonacci_epoch[class]=Fibonacci_epoch;
        _genesis_nonce_time[class]=0;
        
        for (uint i = 0; i<_classCreated.length; i++) {
            if (i==class){
                return true;
            }
        }
        _classCreated.push(class);
        return true;
    }   
    
    function totalSupply( uint256 class, uint256 nonce) public override view returns (uint256) {
    
       return _activeSupply[class][nonce]+_burnedSupply[class][nonce]+_redeemedSupply[class][nonce];
    }
    
    function activeSupply( uint256 class, uint256 nonce) public override view returns (uint256) {
    
       return _activeSupply[class][nonce];
    }
    function burnedSupply( uint256 class, uint256 nonce) public override view  returns (uint256) {
    
        return _burnedSupply[class][nonce];
    }
    
    function redeemedSupply(  uint256 class, uint256 nonce) public override view  returns (uint256) {
    
        return _redeemedSupply[class][nonce];
    }
    
    function balanceOf(address account, uint256 class, uint256 nonce) public override view returns (uint256){
        require(account != address(0), "ERC659: balance query for the zero address");
        return _balances[account][class][nonce];
    }
    
     
    function batchBalanceOf(address account, uint256 class) public override view returns(uint256[] memory){
        uint256[] memory balancesAllNonce = new uint256[](last_bond_nonce[class]);
        for (uint i = 0; i<last_bond_nonce[class]; i++) {
            balancesAllNonce[i]=_balances[account][class][i];
            
        }
        return (balancesAllNonce);
    }
    
    function getBondSymbol(uint256 class) view public override returns (string memory){
        
        return _Symbol[class]; 
    } 
    
    function getBondInfo(uint256 class, uint256 nonce) public override view returns (string memory BondSymbol, uint256 timestamp, uint256 info2, uint256 info3, uint256 info4, uint256 info5,uint256 info6) {
        BondSymbol=_Symbol[class];
        timestamp=_info[class][nonce][1];
        info2=_info[class][nonce][2];
        info3=_info[class][nonce][3];
        info4=_info[class][nonce][4];
        info5=_info[class][nonce][5];
        info6=_info[class][nonce][6];
    }
    
    function bondIsRedeemable(uint256 class, uint256 nonce) public override view returns (bool){
        if(last_bond_redeemed[class] >= nonce){
            return(true);
        }
        
        if(uint(_info[class][nonce][1])<now){
            uint256 total_liquidity=last_activeSupply[class];
            uint256 needed_liquidity=last_activeSupply[class];
            //uint256 available_liquidity;
    
            for (uint i=last_bond_redeemed[class]; i<=last_bond_nonce[class]; i++) {
                total_liquidity += _activeSupply[class][i]+_redeemedSupply[class][i];
                }
            
            for (uint i=last_bond_redeemed[class]; i<=nonce; i++) {
                needed_liquidity += (_activeSupply[class][i]+_redeemedSupply[class][i])*2;
                }
                
            if(total_liquidity>=needed_liquidity){
               
                return(true);
                
                }
            
            else{
                return(false);
            }
         }
         
    else{
            return(false);
        }

             
    }
    
    function _writeLastLiquidity(uint256 class, uint256 nonce) internal returns (bool){
  
    
        uint256 total_liquidity;
        //uint256 available_liquidity;

        for (uint i=last_bond_redeemed[class]; i<nonce; i++) {
            total_liquidity += last_activeSupply[class] + _activeSupply[class][i]+_redeemedSupply[class][i];
       
                
        } 
        last_activeSupply[class]=total_liquidity;
    }
         
    function _createBond(address _to, uint256 class, uint256 nonce, uint256 _amount) private returns(bool) {
    
        if(last_bond_nonce[class]<nonce){
            last_bond_nonce[class]=nonce;
        }
        _nonceCreated[class].push(nonce);
        _info[class][nonce][1]=_genesis_nonce_time[class] + (nonce) * _Fibonacci_epoch[class];
        _balances[_to][class][nonce]+=_amount;
        _activeSupply[class][nonce]+=_amount;
        emit eventIssueBond(msg.sender, _to, class,nonce, _amount);
        return(true);
    }
    
    function _issueBond(address _to, uint256 class, uint256 nonce, uint256 _amount) private returns(bool) {
        if (totalSupply(class,nonce)==0){
            _createBond(_to,class,nonce,_amount);
            return(true);
            }
            
        else{
            _balances[_to][class][nonce]+=_amount;
            _activeSupply[class][nonce]+=_amount;
            emit eventIssueBond(msg.sender, _to, class,last_bond_nonce[class], _amount);
            return(true);
            }
    } 
    
    function _redeemBond(address _from, uint256 class, uint256 nonce, uint256 _amount) private returns(bool) {
       
        _balances[_from][class][nonce]-=_amount;
        _activeSupply[class][nonce]-=_amount;
        _redeemedSupply[class][nonce]+=_amount;
        emit eventRedeemBond( msg.sender,_from, class, nonce, _amount);
        return(true);
    }  
    
    function _transferBond(address _from, address _to, uint256 class, uint256 nonce, uint256 _amount) private returns(bool){      
        _balances[_from][class][nonce]-=_amount;
        _balances[_to][class][nonce]+=_amount;
        emit eventTransferBond( msg.sender,_from,_to, class, nonce, _amount);
        return(true);
    
    }
    
    function _burnBond(address _from, uint256 class, uint256 nonce, uint256 _amount) private returns(bool){      
        _balances[_from][class][nonce]-=_amount;
        emit eventBurnBond( msg.sender,_from, class, nonce, _amount);
        return(true);
    
    }
            
     function issueBond(address _to, uint256  class, uint256 _amount) external override returns(bool){
        require(contract_is_active == true);
        require(msg.sender==bank_contract, "ERC659: operator unauthorized");
        require(_to != address(0), "ERC659: issue bond to the zero address");
        require(_amount >= 1*10**16, "ERC659: invalid amount");
        if(_genesis_nonce_time[class]==0){_genesis_nonce_time[class]=now-now % _Fibonacci_epoch[class];}
        uint256  now_nonce=(now-_genesis_nonce_time[class])/_Fibonacci_epoch[class];
        uint256 FibonacciTimeEponge0=1;
        uint256 FibonacciTimeEponge1=2;
        uint256 FibonacciTimeEponge;
        uint256 amount_out_eponge;
        for (uint i=0; i<_Fibonacci_number[class]; i++) {
            if(i==0){FibonacciTimeEponge=1;}
            else{
                if(i==1){FibonacciTimeEponge=2;}
                else{
                    FibonacciTimeEponge=(FibonacciTimeEponge0+FibonacciTimeEponge1);
                    FibonacciTimeEponge0=FibonacciTimeEponge1;
                    FibonacciTimeEponge1=FibonacciTimeEponge;
                    
            }
        }   
            amount_out_eponge+=FibonacciTimeEponge;     
    }
        
        amount_out_eponge=_amount*1e6/amount_out_eponge;
        FibonacciTimeEponge=0;
        FibonacciTimeEponge0=1;
        FibonacciTimeEponge1=2;
        for (uint i=0; i<_Fibonacci_number[class]; i++) {
            if(i==0){FibonacciTimeEponge=1;}
            else{
                if(i==1){FibonacciTimeEponge=2;}
                else{
                    FibonacciTimeEponge=(FibonacciTimeEponge0+FibonacciTimeEponge1);
                    FibonacciTimeEponge0=FibonacciTimeEponge1;
                    FibonacciTimeEponge1=FibonacciTimeEponge;
                }
            }   
            require(_issueBond( _to, class, now_nonce + FibonacciTimeEponge, amount_out_eponge * FibonacciTimeEponge/1e6) == true);
        }    
      return(true);
    }
    
    function redeemBond(address _from, uint256 class, uint256[] calldata nonce, uint256[] calldata  _amount) external override returns(bool){
        require(contract_is_active == true);
        require(msg.sender==bank_contract || msg.sender==_from, "ERC659: operator unauthorized");
        for (uint i=0; i<nonce.length; i++) {
            require(_balances[_from][class][nonce[i]] >= _amount[i], "ERC659: not enough bond for redemption");
            require(bondIsRedeemable(class,nonce[i])==true, "ERC659: can't redeem bond before it's redemption day");
            require(_redeemBond(_from,class,nonce[i],_amount[i]));
            
            if(last_bond_redeemed[class] < nonce[i]){

            _writeLastLiquidity(class,nonce[i]);
            last_bond_redeemed[class]=nonce[i];
            }
        }
        
        
        return(true);

       
    }
    function transferBond(address _from, address _to, uint256[] calldata class, uint256[] calldata nonce, uint256[] calldata _amount) external override returns(bool){ 
        require(contract_is_active == true);
        for (uint n=0; n<nonce.length; n++) {
            require(msg.sender==bank_contract || msg.sender==exchange_contract, "ERC659: operator unauthorized");
            require(_balances[_from][class[n]][nonce[n]] >= _amount[n], "ERC659: not enough bond to transfer");
            require(_to!=address(0), "ERC659: cant't transfer to zero bond, use 'burnBond()' instead");
            require(_transferBond(_from, _to, class[n], nonce[n], _amount[n]));
           
            
        }
        return(true);
    }
    function burnBond(address _from, uint256[] calldata class, uint256[] calldata nonce, uint256[] calldata _amount) external override returns(bool){
        require(contract_is_active == true);
        for (uint n=0; n<nonce.length; n++) {
            require(msg.sender==bank_contract || msg.sender==_from, "ERC659: operator unauthorized");
            require(_balances[_from][class[n]][nonce[n]] >= _amount[n], "ERC659: not enough bond to burn");
            require(_burnBond(_from, class[n], nonce[n], _amount[n]));
           
            
        }
        return(true);
    }
}