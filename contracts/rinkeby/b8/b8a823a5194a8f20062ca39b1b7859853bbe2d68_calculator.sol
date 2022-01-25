/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

//SPDX-License-Identifier:MIT

pragma solidity >=0.6.7;

contract calculator{

int[] values;
string  operation;
int public sum; 
int public subtract;
int public division;
int  public multiplication;



function set_value_operation(int[] memory _value,string memory oper) public{

for(uint i=0 ; i<_value.length ; i++)
{
        values.push(_value[i]);
        if(keccak256(abi.encode(oper)) == keccak256(abi.encode("sum"))){
            sum= sum + values[i];}
            if(keccak256(abi.encode(oper)) == keccak256(abi.encode("multiply"))){
                if(i==0){
                multiplication=multiplication+values[i];
            }
            multiplication= multiplication * values[i];}
            if(keccak256(abi.encode(oper)) == keccak256(abi.encode("divide"))){
                if(i==0){
                 division=division+values[i];
                 }
            division= division / values[i];}
            if(keccak256(abi.encode(oper)) == keccak256(abi.encode("subtract"))){
                if(i==0){
                subtract=subtract+values[i];
            }
            subtract= subtract - values[i];
            
        } 
    }

}
        }