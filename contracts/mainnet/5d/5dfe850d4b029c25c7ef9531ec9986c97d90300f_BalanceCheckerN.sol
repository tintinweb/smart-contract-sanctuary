pragma solidity ^0.4.19;

/*
    Utility contract for Arby and it&#39;s various exchanges
    Some of these functions originated from (and then improved upon) DeltaBalances.github.io
    Check balances for multiple ERC20 tokens for multiple users in 1 batched call
    Check exchange rates for many Bancor contracts in one batched call
*/

// WETH interface for 0x
contract WETH_0x {
    // function balanceOf(address /*user*/) public view returns (uint);
    function balanceOf(address userAddress) public view returns (uint);
}

// ERC20 interface
contract Token {
    // function balanceOf(address /*tokenOwner*/) public view returns (uint /*balance*/);
    // function transfer(address /*to*/, uint /*tokens*/) public returns (bool /*success*/);
    // function allowance(address _owner, address _spender) constant returns (uint /*remaining*/)
    function balanceOf(address tokenOwner) public view returns (uint /*balance*/);
    function transfer(address toAddress, uint tokens) public returns (bool /*success*/);
    function allowance(address _owner, address _spender) constant returns (uint /*remaining*/);
}


contract BalanceCheckerN {

    address public admin;

    constructor() {
        admin = 0x96670A91E1A0dbAde97fCDC0ABdDEe769C21fc8e;
    }

    //default function, don&#39;t accept any ETH
    function() public payable {
        revert();
    }

    //limit address to the creating address
    modifier isAdmin() {
        require(msg.sender == admin);
         _;
    }

    // selfdestruct for cleanup
    function destruct() public isAdmin {
        selfdestruct(admin);
    }

    // backup withdraw, if somehow ETH gets in here
    function withdraw() public isAdmin {
        admin.transfer(address(this).balance);
    }

    // backup withdraw, if somehow ERC20 tokens get in here
    function withdrawToken(address token, uint amount) public isAdmin {
        require(token != address(0x0)); //use withdraw for ETH
        require(Token(token).transfer(msg.sender, amount));
    }

  /* Check the token allowance of a wallet in a token contract
     Avoids possible errors:
        - returns 0 on invalid exchange contract
        - return 0 on non-contract address

     Mainly for internal use, but public for anyone who thinks it is useful    */
   function tokenAllowance(address user, address spender, address token) public view returns (uint) {
       //  check if token is actually a contract
        uint256 tokenCode;
        assembly { tokenCode := extcodesize(token) } // contract code size
        if(tokenCode > 0)
        {
            Token tok = Token(token);
            //  check if allowance succeeds
            if(address(tok).call(bytes4(keccak256("allowance(address,address)")), user, spender)) {
                return tok.allowance(user, spender);
            } else {
                  return 0; // not a valid allowance, return 0 instead of error
            }
        } else {
            return 0; // not a contract, return 0 instead of error
        }
   }

  /* Check the token balance of a wallet in a token contract
     Avoids possible errors:
        - returns 0 on invalid exchange contract
        - return 0 on non-contract address

     Mainly for internal use, but public for anyone who thinks it is useful    */
   function tokenBalance(address user, address token) public view returns (uint) {
       //  check if token is actually a contract
        uint256 tokenCode;
        assembly { tokenCode := extcodesize(token) } // contract code size
        if(tokenCode > 0)
        {
            Token tok = Token(token);
            //  check if balanceOf succeeds
            if(address(tok).call(bytes4(keccak256("balanceOf(address)")), user)) {
                return tok.balanceOf(user);
            } else {
                  return 0; // not a valid balanceOf, return 0 instead of error
            }
        } else {
            return 0; // not a contract, return 0 instead of error
        }
   }

    /* Check the token balances of a wallet for multiple tokens
       Uses tokenBalance() to be able to return, even if a token isn&#39;t valid
       Possible error throws:
           - extremely large arrays (gas cost too high)

       Returns array of token balances in wei units. */
    function walletBalances(address user,  address[] tokens) public view returns (uint[]) {
        require(tokens.length > 0);
        uint[] memory balances = new uint[](tokens.length);

        for(uint i = 0; i< tokens.length; i++){
            if( tokens[i] != address(0x0) ) { // ETH address in Etherdelta config
                balances[i] = tokenBalance(user, tokens[i]);
            }
            else {
               balances[i] = user.balance; // eth balance
            }
        }
        return balances;
    }

    /* Check the token allowances of a wallet for multiple tokens
       Uses tokenBalance() to be able to return, even if a token isn&#39;t valid
       Possible error throws:
           - extremely large arrays (gas cost too high)

       Returns array of token allowances in wei units. */
    function walletAllowances(address user,  address spender, address[] tokens) public view returns (uint[]) {
        require(tokens.length > 0);
        uint[] memory allowances = new uint[](tokens.length);

        for(uint i = 0; i< tokens.length; i++){
            allowances[i] = tokenAllowance(user, spender, tokens[i]);
        }
        return allowances;
    }

    /* Similar to walletA, with the addition of supporting multiple users
       When calling this funtion through Infura, it handles a large number of users/tokens before it
       fails and returns 0x0 as the result. So there is some max number of arguements you can send...
       */
    function allAllowancesForManyAccounts(
        address[] users,
        address spender,
        address[] tokens)
    public view returns (uint[]) {
        uint[] memory allowances = new uint[](tokens.length * users.length);

        for(uint user = 0; user < users.length; user++){
            for(uint token = 0; token < tokens.length; token++) {
                    allowances[(user * tokens.length) + token] = tokenAllowance(users[user], spender, tokens[token]);
          }
        }
        return allowances;
    }

    /* Similar to allBalances, with the addition of supporting multiple users
       When calling this funtion through Infura, it handles a large number of users/tokens before it
       fails and returns 0x0 as the result. So there is some max number of arguements you can send...
       */
    function allBalancesForManyAccounts(
        address[] users,
        address[] tokens)
    public view returns (uint[]) {
        uint[] memory balances = new uint[](tokens.length * users.length);

        for(uint user = 0; user < users.length; user++){
            for(uint token = 0; token < tokens.length; token++){
                if( tokens[token] != address(0x0) ) { // ETH address in Etherdelta config
                    balances[(user * tokens.length) + token] = tokenBalance(users[user], tokens[token]);
                } else {
                   balances[(user * tokens.length) + token] =  users[user].balance;
                }
            }
        }
        return balances;
    }

    /* Check the balances of many address&#39; WETH (which is a 0x ETH wrapper for 0x exchanges)
       */
    function allWETHbalances(
        address wethAddress,
        address[] users
    ) public view returns (uint[]) {
        WETH_0x weth = WETH_0x(wethAddress);
        uint[] memory balances = new uint[](users.length);
        for(uint k = 0; k < users.length; k++){
            balances[k] = weth.balanceOf(users[k]);
        }
        return balances;
    }
}