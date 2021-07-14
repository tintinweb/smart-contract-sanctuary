/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

pragma solidity >=0.5.10;

//      ****************************************************      //
//                         ICO Art Token                          //
//      ****************************************************      //

/*
        ██║░░░█████╗░░█████╗░░░░░░░░█████╗░██████╗░████████╗
        ██║░██║░░░██║██╔══██╗░░░░░░██╔══██╗██╔══██╗╚══██╔══╝
        ██║░██║░░╚═╝║██║░░██║░░░░░░███████║██████╔╝░░░██║░░░
        ██║░██║░░░██║██║░░██║░░░░░░██╔══██║██╔══██╗░░░██║░░░
        ██║░ ╚█████╔╝░╚████╔╝░░░░░░██║░░██║██║░░██║░░░██║░░░
        ╚═╝░░╚═════╝░░╚════╝░░░░░░░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░

                    ██║░█████╗░██████╗░████████╗
                    ██║██╔══██╗██╔══██╗╚══██╔══╝
████████            ██║███████║██████╔╝░░░██║░░░            ████████
                    ██║██╔══██║██╔══██╗░░░██║░░░
                    ██║██║░░██║██║░░██║░░░██║░░░
                    ╚═╝╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░
*/
//      ****************************************************      //
//                              2021                              //
//      ****************************************************      //

//-----------------------------------------------------------------------------


//
// Symbol        : IART
// Name          : ICOArt Token
// Total supply  : 10000000000
// Decimals      : 8
// Owner Account : 0xC96c4258a7cf6B3e3DC2D74dcb2093474B0f19Bf
//
//
// (c) by ICOArtsToken 2021. 
// ----------------------------------------------------------------------------


//      ****************************************************      //



contract ICOArtsToken {
    // Track how many tokens are owned by each address.
    mapping (address => uint256) public balanceOf;


    string public name = "ICOArt Token";
    string public symbol = "IART";
    uint8 public decimals = 8;
    uint256 public totalSupply = 10000000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    
   // Contract constructor.
   // It sets the `msg.sender` as the proxy administrator.
   // @param _implementation address of the initial implementation.
   //

    constructor() public {
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // for more details about how this works.
    // Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        emit Transfer(account, address(0), amount);
    }
    
    
    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;


    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}

/**
* Copyright 2021
*
* Permission is hereby granted, free of charge, to any person obtaining a copy 
* of this software and associated documentation files (the "Software"), to deal 
* in the Software without restriction, including without limitation the rights 
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
* copies of the Software, and to permit persons to whom the Software is furnished to 
* do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all 
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

//      ********************** ICOArts Token 2021 *************************      //