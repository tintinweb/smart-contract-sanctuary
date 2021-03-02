/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

/**
 *Submitted for verification at Etherscan.io on 2018-07-28
*/

/***
 * ██████╗ █████╗██████╗██████╗██╗    ███████╗     █████╗████████╗██████╗██████╗ ██████╗██████╗███████╗
 * ██╔══████╔══████╔══████╔══████║    ██╔════╝    ██╔══██████╔══████╔══████╔══████╔═══████╔══████╔════╝
 * ██║  ███████████████╔██████╔██║    █████╗      ███████████████╔██║  ████████╔██║   ████████╔███████╗
 * ██║  ████╔══████╔═══╝██╔═══╝██║    ██╔══╝      ██╔══██████╔══████║  ████╔══████║   ████╔═══╝╚════██║
 * ██████╔██║  ████║    ██║    ██████████████╗    ██║  ██████║  ████████╔██║  ██╚██████╔██║    ███████║
 * ╚═════╝╚═╝  ╚═╚═╝    ╚═╝    ╚══════╚══════╝    ╚═╝  ╚═╚═╚═╝  ╚═╚═════╝╚═╝  ╚═╝╚═════╝╚═╝    ╚══════╝
 *        
 * 
 * @author Zenos Pavlakou
 */
 
 
 /***
  * 
  * TODO LIST 
  * 
  * Ensure affiliates cannot be affiliated with themselves.
  * 
  * Add function to allow users to pay to become an affiliate. 
  * 
  * 
  * 
  **/
pragma solidity ^0.8.0;

library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        
        c = a * b;
        assert(c / a == b);
        return c;
    }
    

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }


    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }


    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



contract Ownable {
    
    address public owner;
    
    event OwnershipTransferred(address indexed from, address indexed to);
    
    
    /**
     * Constructor assigns ownership to the address used to deploy the contract.
     * */
    constructor() {
        owner = msg.sender;
    }


    /**
     * Any function with this modifier in its method signature can only be executed by
     * the owner of the contract. Any attempt made by any other account to invoke the 
     * functions with this modifier will result in a loss of gas and the contract's state
     * will remain untampered.
     * */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * Allows for the transfer of ownership to another address;
     * 
     * @param _newOwner The address to be assigned new ownership.
     * */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(
            _newOwner != address(0)
            && _newOwner != owner 
        );
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



/**
 * Contract acts as an interface between the DappleAirdrops contract and all ERC20 compliant
 * tokens. 
 * */
abstract contract ERCInterface {
    function transferFrom(address _from, address _to, uint256 _value) public virtual;
    function balanceOf(address who)  public virtual returns (uint256);
    function allowance(address owner, address spender)  public view virtual returns (uint256);
    function transfer(address to, uint256 value) public virtual returns(bool);
}



contract DappleAirdrops is Ownable {
    
    using SafeMath for uint256;
    
    mapping (address => uint256) public bonusDropsOf;
    mapping (address => uint256) public ethBalanceOf;
    mapping (address => uint256) public trialDrops;
    mapping (address => bool) public isVIP;
    mapping (address => bool) public isAffiliate;
    mapping (string => address) public affiliateCodeToAddr;
    mapping (string => bool) public affiliateCodeExists;
    mapping (address => string) public affiliateCodeOfAddr;
    mapping (address => string) public isAffiliatedWith;
        
    uint256 public vipFee;
    uint256 public rate;
    uint256 public dropUnitPrice;
    uint256 public bonus;

    event BonusCreditGranted(address indexed to, uint256 credit);
    event BonusCreditRevoked(address indexed from, uint256 credit);
    event CreditPurchased(address indexed by, uint256 etherValue, uint256 credit);
    event AirdropInvoked(address indexed by, uint256 creditConsumed);
    event BonustChanged(uint256 from, uint256 to);
    event TokenBanned(address indexed tokenAddress);
    event TokenUnbanned(address indexed tokenAddress);
    event EthWithdrawn(address indexed by, uint256 totalWei);
    event RateChanged(uint256 from, uint256 to);
    event MaxDropsChanged(uint256 from, uint256 to);
    event RefundIssued(address indexed to, uint256 totalWei);
    event ERC20TokensWithdrawn(address token, address sentTo, uint256 value);

    
    /**
     * Constructor sets the rate such that 1 ETH = 10,000 credits (i.e., 10,000 airdrop recipients)
     * which equates to a unit price of 0.00001 ETH per airdrop recipient. The bonus percentage
     * is set to 20% but is subject to change. Bonus credits will only be issued after once normal
     * credits have been used (unless credits have been granted to an address by the owner of the 
     * contract).
     * */
    constructor() {
        rate = 10000;
        dropUnitPrice = 1e14; 
        bonus = 20;
        vipFee = 25e16;
    }
    
    function setVIPFee(uint256 _fee) public onlyOwner returns(bool) {
        require(_fee > 0 && _fee != vipFee);
        vipFee = _fee;
        return true;
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function becomeVIP() public payable returns(bool) {
        require(!isVIP[msg.sender], "Is already VIP member");
        require(msg.value >= vipFee, uint2str(vipFee));
        
        isVIP[msg.sender] = true;
        
        if(msg.value > vipFee) {
            uint256 remainder = msg.value.sub(vipFee);
            payable(msg.sender).transfer(remainder);
        }
        
        payable(owner).transfer(vipFee);
        return true; 
    }
    
    
    function addAffiliate(address _addr, string memory _code) public onlyOwner returns(bool) {
        require(!isAffiliate[_addr] && _addr != address(0));
        require(!affiliateCodeExists[_code]);
        affiliateCodeExists[_code] = true;
        isAffiliate[_addr] = true;
        affiliateCodeToAddr[_code] = _addr;
        affiliateCodeOfAddr[_addr] = _code;
        return true;
    }
    
    
    function removeAffiliate(address _addr) public onlyOwner returns(bool) {
        require(isAffiliate[_addr]);
        isAffiliate[_addr] = false;
        affiliateCodeToAddr[affiliateCodeOfAddr[_addr]] = address(0);
        affiliateCodeOfAddr[_addr] = "No longer an affiliate partner";
        return true;
    }
    

    
    /**
     * Checks whether or not an ERC20 token has used its free trial of 100 drops. This is a constant 
     * function which does not alter the state of the contract and therefore does not require any gas 
     * or a signature to be executed. 
     * 
     * @param _addressOfToken The address of the token being queried.
     * 
     * @return true if the token being queried has not used its 100 first free trial drops, false
     * otherwise.
     * */
    function tokenHasFreeTrial(address _addressOfToken) public view returns(bool) {
        return trialDrops[_addressOfToken] < 100;
    }
    
    
    /**
     * Checks how many remaining free trial drops a token has.
     * 
     * @param _addressOfToken the address of the token being queried.
     * 
     * @return the total remaining free trial drops of a token.
     * */
    function getRemainingTrialDrops(address _addressOfToken) public view returns(uint256) {
        if(tokenHasFreeTrial(_addressOfToken)) {
            uint256 maxTrialDrops =  100;
            return maxTrialDrops.sub(trialDrops[_addressOfToken]);
        } 
        return 0;
    }
    
    
    /**
     * Allows for the price of drops to be changed by the owner of the contract. Any attempt made by 
     * any other account to invoke the function will result in a loss of gas and the price will remain 
     * untampered.
     * 
     * @return true if function executes successfully, false otherwise.
     * */
    function setRate(uint256 _newRate) public onlyOwner returns(bool) {
        require(
            _newRate != rate 
            && _newRate > 0
        );
        emit RateChanged(rate, _newRate);
        rate = _newRate;
        uint256 eth = 1 ether;
        dropUnitPrice = eth.div(rate);
        return true;
    }
    
    
    function getRate() public view returns(uint256) {
        return rate;
    }


    
    /**
     * Allows for the bonus to be changed at any point in time by the owner of the contract. Any
     * attempt made by any other account to invoke the function will result in a loss of gas and 
     * the bonus will remain untampered.
     * 
     * @param _newBonus The value of the new bonus to be set.
     * */
    function setBonus(uint256 _newBonus) public onlyOwner returns(bool) {
        require(bonus != _newBonus);
        emit BonustChanged(bonus, _newBonus);
        bonus = _newBonus;
    }
    
    
    /**
     * Allows for bonus drops to be granted to a recipient address by the owner of the contract. 
     * Any attempt made by any other account to invoke the function will result in a loss of gas 
     * and the bonus drops of the recipient will remain untampered.
     * 
     * @param _addr The address which will receive bonus credits.
     * @param _bonusDrops The amount of bonus drops to be granted.
     * 
     * @return true if function executes successfully, false otherwise.
     * */
    function grantBonusDrops(address _addr, uint256 _bonusDrops) public onlyOwner returns(bool) {
        require(
            _addr != address(0) 
            && _bonusDrops > 0
        );
        bonusDropsOf[_addr] = bonusDropsOf[_addr].add(_bonusDrops);
        emit BonusCreditGranted(_addr, _bonusDrops);
        return true;
    }
    
    
    /**
     * Allows for bonus drops of an address to be revoked by the owner of the contract. Any 
     * attempt made by any other account to invoke the function will result in a loss of gas
     * and the bonus drops of the recipient will remain untampered.
     * 
     * @param _addr The address to revoke bonus credits from.
     * @param _bonusDrops The amount of bonus drops to be revoked.
     * 
     * @return true if function executes successfully, false otherwise.
     * */
    function revokeBonusCreditOf(address _addr, uint256 _bonusDrops) public onlyOwner returns(bool) {
        require(
            _addr != address(0) 
            && bonusDropsOf[_addr] >= _bonusDrops
        );
        bonusDropsOf[_addr] = bonusDropsOf[_addr].sub(_bonusDrops);
        emit BonusCreditRevoked(_addr, _bonusDrops);
        return true;
    }
    
    
    /**
     * Allows for the credit of an address to be queried. This is a constant function which
     * does not alter the state of the contract and therefore does not require any gas or a
     * signature to be executed. 
     * 
     * @param _addr The address of which to query the credit balance of. 
     * 
     * @return The total amount of credit the address has (minus any bonus credits).
     * */
    function getDropsOf(address _addr) public view returns(uint256) {
        return (ethBalanceOf[_addr].mul(rate)).div(10 ** 18);
    }
    
    
    /**
     * Allows for the bonus credit of an address to be queried. This is a constant function 
     * which does not alter the state of the contract and therefore does not require any gas 
     * or a signature to be executed. 
     * 
     * @param _addr The address of which to query the bonus credits. 
     * 
     * @return The total amount of bonus credit the address has (minus non-bonus credit).
     * */
    function getBonusDropsOf(address _addr) public view returns(uint256) {
        return bonusDropsOf[_addr];
    }
    
    
    /**
     * Allows for the total credit (bonus + non-bonus) of an address to be queried. This is a 
     * constant function which does not alter the state of the contract and therefore does not  
     * require any gas or a signature to be executed. 
     * 
     * @param _addr The address of which to query the total credits. 
     * 
     * @return The total amount of credit the address has (bonus + non-bonus credit).
     * */
    function getTotalDropsOf(address _addr) public view returns(uint256) {
        return getDropsOf(_addr).add(getBonusDropsOf(_addr));
    }
    
    
    /**
     * Allows for the total ETH balance of an address to be queried. This is a constant
     * function which does not alter the state of the contract and therefore does not  
     * require any gas or a signature to be executed. 
     * 
     * @param _addr The address of which to query the total ETH balance. 
     * 
     * @return The total amount of ETH balance the address has.
     * */
    function getEthBalanceOf(address _addr) public view returns(uint256) {
        return ethBalanceOf[_addr];
    }

    
    
    /**
     * Allows for the allowance of a token from its owner to this contract to be queried. 
     * 
     * As part of the ERC20 standard all tokens which fall under this category have an allowance 
     * function which enables owners of tokens to allow (or give permission) to another address 
     * to spend tokens on behalf of the owner. This contract uses this as part of its protocol.
     * Users must first give permission to the contract to transfer tokens on their behalf, however,
     * this does not mean that the tokens will ever be transferrable without the permission of the 
     * owner. This is a security feature which was implemented on this contract. It is not possible
     * for the owner of this contract or anyone else to transfer the tokens which belong to others. 
     * 
     * @param _addr The address of the token's owner.
     * @param _addressOfToken The contract address of the ERC20 token.
     * 
     * @return The ERC20 token allowance from token owner to this contract. 
     * */
    function getTokenAllowance(address _addr, address _addressOfToken) public view returns(uint256) {
        ERCInterface token = ERCInterface(_addressOfToken);
        return token.allowance(_addr, address(this));
    }
    
    
    /**
     * Allows users to buy and receive credits automatically when sending ETH to the contract address.
     * */
    fallback() external payable {
        ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].add(msg.value);
        emit CreditPurchased(msg.sender, msg.value, msg.value.mul(rate));
    }

    
    /**
     * Allows users to withdraw their ETH for drops which they have bought and not used. This 
     * will result in the credit of the user being set back to 0. However, bonus credits will 
     * remain the same because they are granted when users use their drops. 
     * 
     * @param _eth The amount of ETH to withdraw
     * 
     * @return true if function executes successfully, false otherwise.
     * */
    function withdrawEth(uint256 _eth) public returns(bool) {
        require(
            ethBalanceOf[msg.sender] >= _eth
            && _eth > 0 
        );
        uint256 toTransfer = _eth;
        ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].sub(_eth);
        payable(msg.sender).transfer(toTransfer);
        emit EthWithdrawn(msg.sender, toTransfer);
    }
    
    
    /**
     * Allows for refunds to be made by the owner of the contract. Any attempt made by any other account 
     * to invoke the function will result in a loss of gas and no refunds will be made.
     * */
    function issueRefunds(address[] memory _addrs) public onlyOwner returns(bool) {
        for(uint i = 0; i < _addrs.length; i++) {
            if(_addrs[i] != address(0) && ethBalanceOf[_addrs[i]] > 0) {
                uint256 toRefund = ethBalanceOf[_addrs[i]];
                ethBalanceOf[_addrs[i]] = 0;
                payable(_addrs[i]).transfer(toRefund);
                emit RefundIssued(_addrs[i], toRefund);
            }
        }
    }
    
    
    function stringsAreEqual(string memory a, string memory b) internal pure returns(bool) {
        bytes32 hashA = keccak256(abi.encodePacked(a));
        bytes32 hashB = keccak256(abi.encodePacked(b));
        return hashA == hashB;
    }
 
    
    
    function singleValueEthDrop(address[] memory _recipients, uint256 _value, string memory _afCode) public payable returns(bool) {
        require(getTotalDropsOf(msg.sender)>=_recipients.length || isVIP[msg.sender]);
        require(msg.value >= _value.mul(_recipients.length));
        
        if(!stringsAreEqual(_afCode, "") && stringsAreEqual(isAffiliatedWith[msg.sender],"")) {
            isAffiliatedWith[msg.sender] = _afCode;
        }

        if(stringsAreEqual(_afCode,"") && !stringsAreEqual(isAffiliatedWith[msg.sender],"")) {
            _afCode = isAffiliatedWith[msg.sender];
        }
        
        
        if(!isVIP[msg.sender]) {
            updateMsgSenderBonusDrops(_recipients.length, _afCode);
        }

        if(msg.value > _value.mul(_recipients.length)) {
            uint256 remainder = msg.value.sub(_value.mul(_recipients.length));
            payable(msg.sender).transfer(remainder);
        }
        
        for(uint i=0; i<_recipients.length; i++) {
            if(_recipients[i] != address(0)) {
                payable(_recipients[i]).transfer(_value);
            }
        }
        
        
    
        emit AirdropInvoked(msg.sender, _recipients.length);
        
        
        return true;
    }
    
    
    function _getTotalEthValue(uint256[] memory _values) internal pure returns(uint256) {
        uint256 totalVal = 0;
        for(uint i = 0; i < _values.length; i++) {
            totalVal = totalVal.add(_values[i]);
        }
        return totalVal;
    }
    
    
    function multiValueEthDrop(address[] memory _recipients, uint256[] memory _values, string memory _afCode) public payable returns(bool) {
        require(_recipients.length == _values.length );
        require(getTotalDropsOf(msg.sender)>=_recipients.length || isVIP[msg.sender]);
        
        uint256 totalEthValue = _getTotalEthValue(_values);
        require(msg.value >= totalEthValue);
        
        if(!stringsAreEqual(_afCode, "") && stringsAreEqual(isAffiliatedWith[msg.sender],"")) {
            isAffiliatedWith[msg.sender] = _afCode;
        }

        if(stringsAreEqual(_afCode,"") && !stringsAreEqual(isAffiliatedWith[msg.sender],"")) {
            _afCode = isAffiliatedWith[msg.sender];
        }
        
        if(!isVIP[msg.sender]) {
            updateMsgSenderBonusDrops(_recipients.length, _afCode);
        }
    
        if(msg.value > totalEthValue) {
            uint256 remainder = msg.value.sub(totalEthValue);
           payable(msg.sender).transfer(remainder);
        }
        
        for(uint i = 0; i < _recipients.length; i++) {
            if(_recipients[i] != address(0) && _values[i] > 0) {
                payable(_recipients[i]).transfer(_values[i]);
            }
        }
        
        
        emit AirdropInvoked(msg.sender, _recipients.length);
        return true;
    }
    
    
    /**
     * Allows for the distribution of an ERC20 token to be transferred to up to 100 recipients at 
     * a time. This function only facilitates batch transfers of constant values (i.e., all recipients
     * will receive the same amount of tokens).
     * 
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipients The list of addresses which will receive tokens. 
     * @param _value The amount of tokens all addresses will receive. 
     * 
     * @return true if function executes successfully, false otherwise.
     * */
    function singleValueAirdrop(address _addressOfToken,  address[] memory _recipients, uint256 _value, string memory _afCode) public returns(bool) {
        ERCInterface token = ERCInterface(_addressOfToken);
        require(
            getTotalDropsOf(msg.sender)>= _recipients.length 
            || tokenHasFreeTrial(_addressOfToken) || isVIP[msg.sender]
        );
        
        if(!stringsAreEqual(_afCode, "") && stringsAreEqual(isAffiliatedWith[msg.sender],"")) {
            isAffiliatedWith[msg.sender] = _afCode;
        }

        if(stringsAreEqual(_afCode,"") && !stringsAreEqual(isAffiliatedWith[msg.sender],"")) {
            _afCode = isAffiliatedWith[msg.sender];
        }
        
        for(uint i = 0; i < _recipients.length; i++) {
            if(_recipients[i] != address(0)) {
                token.transferFrom(msg.sender, _recipients[i], _value);
            }
        }
        if(tokenHasFreeTrial(_addressOfToken)) {
            trialDrops[_addressOfToken] = trialDrops[_addressOfToken].add(_recipients.length);
        } else {
            if(!isVIP[msg.sender]) {
                updateMsgSenderBonusDrops(_recipients.length, _afCode);
            }
            
        }
        emit AirdropInvoked(msg.sender, _recipients.length);
        return true;
    }
    
    
    /**
     * Allows for the distribution of an ERC20 token to be transferred to up to 100 recipients at 
     * a time. This function facilitates batch transfers of differing values (i.e., all recipients
     * can receive different amounts of tokens).
     * 
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipients The list of addresses which will receive tokens. 
     * @param _values The corresponding values of tokens which each address will receive.
     * 
     * @return true if function executes successfully, false otherwise.
     * */    
    function multiValueAirdrop(address _addressOfToken,  address[] memory _recipients, uint256[] memory _values, string memory _afCode) public returns(bool) {
        ERCInterface token = ERCInterface(_addressOfToken);
        require(
            _recipients.length == _values.length 
            && (
                getTotalDropsOf(msg.sender) >= _recipients.length
                || tokenHasFreeTrial(_addressOfToken) || isVIP[msg.sender]
            )
        );
        
        if(!stringsAreEqual(_afCode, "") && stringsAreEqual(isAffiliatedWith[msg.sender],"")) {
            isAffiliatedWith[msg.sender] = _afCode;
        }

        if(stringsAreEqual(_afCode,"") && !stringsAreEqual(isAffiliatedWith[msg.sender],"")) {
            _afCode = isAffiliatedWith[msg.sender];
        }
        
        for(uint i = 0; i < _recipients.length; i++) {
            if(_recipients[i] != address(0) && _values[i] > 0) {
                token.transferFrom(msg.sender, _recipients[i], _values[i]);
            }
        }
        if(tokenHasFreeTrial(_addressOfToken)) {
            trialDrops[_addressOfToken] = trialDrops[_addressOfToken].add(_recipients.length);
        } else {
            if(!isVIP[msg.sender]) {
                updateMsgSenderBonusDrops(_recipients.length, _afCode);
            }
        }
        emit AirdropInvoked(msg.sender, _recipients.length);
        return true;
    }
    
            

        

    
    

        
    
    
    /**
     * Invoked internally by the airdrop functions. The purpose of thie function is to grant bonus 
     * drops to users who spend their ETH airdropping tokens, and to remove bonus drops when users 
     * no longer have ETH in their account but do have some bonus drops when airdropping tokens.
     * 
     * @param _drops The amount of recipients which received tokens from the airdrop.
     * */
    function updateMsgSenderBonusDrops(uint256 _drops, string memory _afCode) internal {
        if(_drops <= getDropsOf(msg.sender)) {
            bonusDropsOf[msg.sender] = bonusDropsOf[msg.sender].add(_drops.mul(bonus).div(100));
            ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].sub(_drops.mul(dropUnitPrice));
            if(!stringsAreEqual(_afCode,"") && isAffiliate[affiliateCodeToAddr[_afCode]]) {
                payable(owner).transfer(_drops.mul(dropUnitPrice).div(2));
                payable(affiliateCodeToAddr[_afCode]).transfer(_drops.mul(dropUnitPrice).div(2));
            } else {
                payable(owner).transfer(_drops.mul(dropUnitPrice));
            }
            
        } else {
            uint256 remainder = _drops.sub(getDropsOf(msg.sender));
            bonusDropsOf[msg.sender] = bonusDropsOf[msg.sender].sub(remainder);
            uint256 ethBalance = ethBalanceOf[msg.sender];
            ethBalanceOf[msg.sender] = 0;
            if(ethBalance > 0) {
                bonusDropsOf[msg.sender] = bonusDropsOf[msg.sender].add(getDropsOf(msg.sender).mul(bonus).div(100));
                
                if(!stringsAreEqual(_afCode, "") && isAffiliate[affiliateCodeToAddr[_afCode]]) {
                    payable(owner).transfer(ethBalance.div(2));
                    payable(affiliateCodeToAddr[_afCode]).transfer(ethBalanceOf[msg.sender].div(2));
                } else {
                    payable(owner).transfer(ethBalance);
                }
                
            }
            
        }
    }
    

    /**
     * Allows for any ERC20 tokens which have been mistakenly  sent to this contract to be returned 
     * to the original sender by the owner of the contract. Any attempt made by any other account 
     * to invoke the function will result in a loss of gas and no tokens will be transferred out.
     * 
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipient The address which will receive tokens. 
     * @param _value The amount of tokens to refund.
     * 
     * @return true if function executes successfully, false otherwise.
     * */  
    function withdrawERC20Tokens(address _addressOfToken,  address _recipient, uint256 _value) public onlyOwner returns(bool){
        require(
            _addressOfToken != address(0)
            && _recipient != address(0)
            && _value > 0
        );
        ERCInterface token = ERCInterface(_addressOfToken);
        token.transfer(_recipient, _value);
        emit ERC20TokensWithdrawn(_addressOfToken, _recipient, _value);
        return true;
    }
}