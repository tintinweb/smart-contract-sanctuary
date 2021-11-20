//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.0;

import "IBank.sol";
import "IPriceOracle.sol";


contract PriceOracleTest is IPriceOracle {
    mapping(address => uint256) virtualPrice;
    function getVirtualPrice(address token)
        view
        external
        override
        returns (uint256) {
            if (virtualPrice[token] == 0) {
                return 1 ether;
            } else {
                return virtualPrice[token];
        }
    }
}

contract Bank is IBank {
    
    address public hak_token;
    address public eth_token;
    address public price_oracle;
    address public bank;
    //uint256 public collateral;

    mapping (address => IPriceOracle) oracle;
    
    mapping (address => mapping (address => Account)) acc;
    mapping (address => uint256) borrowed; 
    mapping (address => uint256) owedInterest; 
    mapping (address => uint256) lastLoanInterestBlock;


    constructor (address _priceOracle, address _hakToken) {
        bank = msg.sender;
        price_oracle = _priceOracle;
        //ERC20 hak_token = ERC20(_hakToken);
        hak_token = _hakToken;
        eth_token = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        
    }
    
    function valid_token(address token) internal view returns (bool) {
        return token == eth_token || token == hak_token;
    }
    
    function calc_interest(uint256 last_block_number, uint256 cur_block_number, uint256 interestof, uint256 percent_interest) internal pure returns (uint256) {
        uint256 interest_rate = (cur_block_number - last_block_number) * percent_interest;
        uint256 interest = interestof * interest_rate / 10000;
        return interest;
    }

    function deposit(address token, uint256 amount)
        payable
        external
        override
        returns (bool) {
            if (amount <= 0)
                revert("Amount should be  > 0");
            if (!valid_token(token))
                revert("token not supported");
        
            address payable sender = msg.sender;
            uint256 cur_block_number = block.number;
            if (acc[msg.sender][token].lastInterestBlock > 0)
                acc[msg.sender][token].interest += 
                    calc_interest(acc[msg.sender][token].lastInterestBlock, cur_block_number, acc[msg.sender][token].deposit, 3);
            // update the last interest block
            acc[msg.sender][token].lastInterestBlock = block.number;
            
        
            // deposit
            acc[msg.sender][token].deposit += amount;
            //if (token==eth_token)
                
            //token.call.transferFrom(address(this), msg.sender, amount);
            //sender.balance. -= amount;
            emit Deposit(msg.sender, token, amount);
        
            return true;
        }

    function withdraw(address token, uint256 amount)
        external
        override
        returns (uint256) {
            if (amount < 0)
                revert("Amount should be  >= 0");
            if (!valid_token(token))
                revert("token not supported");
        
            address sender = msg.sender;
            if (acc[sender][token].deposit == 0)
                revert("no balance");
            if (amount > acc[sender][token].deposit)
                revert("amount exceeds balance");
            
            uint256 cur_block_number = block.number;
            // calculate interest
            acc[sender][token].interest += calc_interest(acc[sender][token].lastInterestBlock, cur_block_number, acc[sender][token].deposit, 3);
            acc[sender][token].lastInterestBlock = cur_block_number;

            if (amount == 0)
                amount = acc[sender][token].deposit;
            
            acc[sender][token].deposit -= amount;
            
            uint256 return_amount = amount + acc[sender][token].interest;
            acc[sender][token].interest = 0;
            
            emit Withdraw(msg.sender, token, return_amount);
            return return_amount;
        }

    function borrow(address token, uint256 amount)
        external
        override
        returns (uint256) {
            require(token == eth_token);

            address sender = msg.sender;
            uint256 hak_deposit = acc[sender][hak_token].deposit;
            if (hak_deposit == 0)
                revert("no collateral deposited");

            require(getCollateralRatio(hak_token, sender) >= 15000, "borrow would exceed collateral ratio");
            
            if (amount == 0)
                amount = (hak_deposit + acc[sender][hak_token].interest) * 100 / 150;
            
            acc[sender][token].deposit += amount;
            borrowed[sender] += amount;

            emit Borrow(bank, token, amount, getCollateralRatio(hak_token, sender));
            return amount;
        }

    function repay(address token, uint256 amount)
        payable
        external
        override
        returns (uint256) 
        {
            acc[msg.sender][token].deposit -= amount;
            return amount; 
        }

    function liquidate(address token, address account)
        payable
        external
        override
        returns (bool) 
        {
            // //should the collateral be checked inside, or outisde the function?
            // //if the collateral is lower than 1.5 of the debt, then account go bye bye

            // //hak price in terms of eth
            // uint256 hak_price = oracle[price_oracle].getVirtualPrice(hak_token);
            // require(account[token].hak < 1.5*hak_price*account[token].debt);
            // account[token].hak = 0;
            // ///////
            // return true; 
            
        }

    function getCollateralRatio(address token, address account)
        view
        public
        override
        returns (uint256) 
        {

            require(token == hak_token, "token not supported");

            if(borrowed[account]==0)
            {
                return type(uint256).max;
            }

            uint256 hak_price = oracle[price_oracle].getVirtualPrice(hak_token);
            // TODO: convert ETH to HAK with price oracle !!!
            // DONE?
            uint256 collateral = (acc[account][token].deposit + acc[account][token].interest) * hak_price * 10000 / 
                    (borrowed[account] + owedInterest[account]);
            return collateral;
        }

    function getBalance(address token)
        view
        public
        override
        returns (uint256) 
        {
            address sender = msg.sender;
            return acc[sender][token].deposit + acc[sender][token].interest +
                calc_interest(acc[sender][token].lastInterestBlock, block.number, acc[sender][token].deposit, 3);
        }
}