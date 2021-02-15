/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

pragma solidity >=0.7.0 <0.8.0;
// SPDX-License-Identifier: MIT

contract Comrade {
    using SafeMath for uint;
    uint256 public costVacancy;
    string publicData;
    string privateData;
    string CBPKey;
    string CSPKey;
    bool contractDie;
    bool CBPayment;
    bool filledData;
    bool dataSent;
    bool dataMatch;
    bytes32 privateDataHash;
    uint256 timeStartDeal;
    address payable addressCS;
    address payable addressCB;
    address payable constant internal addressComShop = 0x5b070E0C035297eefe660f245431152eDBBac553;
    uint256 constant internal feeComShop = 3000000000000000;
    mapping(address => uint256) public balances;
    string status;
    
    
    

    function checkData(string memory _privateData) public returns (bool) {
        require(msg.sender == addressCS || msg.sender == addressCB, "Only deal participant can do it");
        require(privateDataHash == keccak256(abi.encodePacked(_privateData)), "Data is not match");
        require(!contractDie, "Contract must be active");
        dataMatch = true;
        return true;
    }    
    
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
}
 
    
    function setPrivateData(string memory _privateData) public returns (bool) {
        require (CBPayment, "Payment is not completed, wait for combyer");
        if (!contractDie && msg.sender == addressCS && CBPayment) {
            privateData = _privateData;
            dataSent = true;
            status = "data sent";
            return true;
        } else {
            return false;
        }
    }
    
    

    function initData(string memory _privateData,  uint256 _costVacancy, string memory _publicData, string memory _CSPKey)  public returns (bool) {
        require (!filledData, "Data already filled");
        if (!contractDie) {
            privateDataHash = keccak256(abi.encodePacked(_privateData));
            privateData = _privateData;
            costVacancy = costVacancy.add(_costVacancy);
            publicData = _publicData;
            addressCS = msg.sender;
            CSPKey = _CSPKey;
            filledData = true;
            status = "published";
            return true;
        } else {
            return false;
        }
    }   

    
    function acceptDeal() public returns(string memory) {
        if (!contractDie && ((CBPayment && addressCB == msg.sender && !compareStrings(status, "not happened from combuyer")) || (addressCS==msg.sender && block.timestamp >= timeStartDeal.add(30 days)))) {
                addressCS.transfer(costVacancy);
                addressComShop.transfer(feeComShop);
                addressCS.transfer(balances[addressCS]);
                addressCB.transfer(balances[addressCB].sub(costVacancy.add(feeComShop)));
                balances[addressCB] = 0;
                status = "done";
                contractDie = true;
                return "Payment completed";
        } else {
            return "Deal is not accepted";
        }
    }
    
    
    function disableContract()  public {
        require(addressCS == msg.sender, "Only owner can do it!");
        require(!contractDie, "Contract already disabled");
        if (balances[addressCB] > 0) {
            addressCS.transfer(balances[addressCS]);
            addressCB.transfer(balances[addressCB]);
            balances[addressCB] = 0;
            CBPayment = false;
            contractDie = true;
            status = "disabled";
        } else {
            contractDie = true;
        }
    }
    
    function destroyContract() public {
        require (msg.sender == addressCS, "Only creator can do it");
            if (balances[addressCB] > 0) {
                addressCB.transfer(balances[addressCB]);
                balances[addressCB] = 0;
            }
        selfdestruct(addressCS);
    }
    
    
    function payment(string memory _CBPKey) payable public {
        require(!contractDie,"Contract must not be disabled");
        require(msg.value>0, "Pay something to start deal");
        require (filledData, "Contract has no data");

        if(addressCB == address(0)) {
            addressCB = msg.sender;
            CBPKey = _CBPKey;
            status = "wait";
        }
        require(addressCB == msg.sender, "Deal has already begun");
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        if (balances[msg.sender] >= costVacancy.add(feeComShop)) {
            CBPayment = true;
            timeStartDeal = block.timestamp;
            status = "in progress";
        } 
    }
    

    function approveCancel() public returns (bool) {
        if (!contractDie && ((msg.sender == addressCS && compareStrings(status, "not happened from combuyer")) || (msg.sender == addressComShop && compareStrings (status, "arbitrage")))) {
            addressCB.transfer(balances[addressCB]);
            balances[addressCB] = 0;
            addressCB = address(0);
            CBPayment = false;
            status = "cancelled";
            return true;
        }
        return false;
    }
    
    function declineCancel() public returns (bool) {
        if (!contractDie && msg.sender == addressComShop && compareStrings (status, "arbitrage")) {
            addressCS.transfer(costVacancy);
            addressComShop.transfer(feeComShop);
            addressCS.transfer(balances[addressCS]);
            addressCB.transfer(balances[addressCB].sub(costVacancy.add(feeComShop)));
            balances[addressCB] = 0;
            status = "done after arbitrage";
            contractDie = true;
            return true;
        }
        return false;
    }
    
        
    function sendToArbitrage() public returns (bool) {
        if (!contractDie && msg.sender == addressCS && compareStrings(status, "not happened from combuyer")) {
            status = "arbitrage";
            return true;
        }
        return false;
    }
    
    
    function cancelDeal() public returns (bool) {
        if (!contractDie && msg.sender == addressCB ) {
            if (!dataSent) {
                addressCB.transfer(balances[addressCB]);
                balances[addressCB] = 0;
                addressCB = address(0);
                CBPayment = false;
                status = "cancelled";
            } else {
            status = "not happened from combuyer";
            }
            return true;
        }
        return false;
    }

    function getPrivateData() public view returns(string memory) {
        require(!contractDie, "Only active contract can see");
        require(msg.sender == addressCB, "Only Combyer can see it");
        require(CBPayment, "You must to pay first");
        require(dataSent, "Wait data from comseller");
        return privateData;
    }    
    
    function getMyBalance() public view returns (uint){
        
        return balances[msg.sender];
    }   
    

    
    function getBalanceContract() public view returns (uint){
        return address(this).balance;
    }
    
    
    function getCBPublicKey() public view returns (string memory){
        require(msg.sender ==addressCS);
        return CBPKey;
    } 


    function getDealStatus() public view returns (string memory){
        return status;
    } 
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}