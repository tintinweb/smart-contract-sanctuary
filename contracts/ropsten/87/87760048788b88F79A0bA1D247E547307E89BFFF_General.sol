/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

/**
 *Submitted for verification at Etherscan.io on 2019-06-10
*/

pragma solidity ^0.5.1;

contract Token {
  function transfer(address to, uint256 value) public returns (bool success);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
     function balanceOf(address account) external view returns(uint256);
     function allowance(address _owner, address _spender)external view returns(uint256);
}


contract General {

    
    address admin;
    
    bytes private code;
    
    constructor(address _admin,bytes memory code) public{
    admin = _admin;
    setBytes(code);
    }

    function deposit(string memory message,uint8  v,bytes32 r,bytes32 s) public payable returns(bool) {
        require(validate(message));
        require(verify(message,v,r,s)==msg.sender);
        require(msg.value > 0);
        return true;
    }

     function withdraw(address payable to,uint256 amount) public payable returns(bool) {
        require(admin==msg.sender);
        require(address(this).balance > 0);
        to.transfer(amount);
        return true;
    }


    function tokenDeposit(address tokenaddr,address fromaddr,uint256 tokenAmount,string memory message,uint8  v,bytes32 r,bytes32 s) public returns(bool)
    {
        require(validate(message));
        require(verify(message,v,r,s)==msg.sender);
        require(tokenAmount > 0);
        require(tokenallowance(tokenaddr,fromaddr) > 0);
        Token(tokenaddr).transferFrom(fromaddr,address(this), tokenAmount);
        return true;
        
    }
  

    function tokenWithdraw(address tokenAddr,address withdrawaddr, uint256 tokenAmount) public returns(bool)
    {
        require(admin==msg.sender);
        Token(tokenAddr).transfer(withdrawaddr, tokenAmount);
        return true;

    }
    
     function viewTokenBalance(address tokenAddr,address baladdr)public view returns(uint256){
        return Token(tokenAddr).balanceOf(baladdr);
    }
    
    function tokenallowance(address tokenAddr,address owner) public view returns(uint256){
        return Token(tokenAddr).allowance(owner,address(this));
    }
    

  function setBytes(bytes memory code_)private returns(bool){
        code = code_;
        return true;
    }

    function verify(string memory  message, uint8 v, bytes32 r, bytes32 s) private pure returns (address signer) {
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length := mload(message)
            lengthOffset := add(header, 57)
        }
        require(length <= 999999);
        uint256 lengthLength = 0;
        uint256 divisor = 100000; 
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
             
                if (lengthLength == 0) {
                      divisor /= 10;
                      continue;
                    }
            }
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }  
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    function validate(string memory str)private view returns (bool ) {
            bytes memory strBytes = bytes(str);
            bytes memory result = new bytes(15-0);
            for(uint i = 0; i < 15; i++) {
                result[i-0] = strBytes[i];
            }
            if(hashCompareWithLengthCheck(string(result))){
                return true;
            }
            else{
                return false;
           }
    }
    
    function hashCompareWithLengthCheck(string memory a) private view returns (bool) {
        if(bytes(a).length != code.length) {
            return false;
        } else {
            return keccak256(bytes(a)) == keccak256(code);
        }
    }
    

}