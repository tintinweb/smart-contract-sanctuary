/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

/***
 *   _____                  _          __  __       _ _   _                    _           
 *  / ____|                | |        |  \/  |     | | | (_)                  | |          
 * | |     _ __ _   _ _ __ | |_ ___   | \  / |_   _| | |_ _ ___  ___ _ __   __| | ___ _ __ 
 * | |    | '__| | | | '_ \| __/ _ \  | |\/| | | | | | __| / __|/ _ \ '_ \ / _` |/ _ \ '__|
 * | |____| |  | |_| | |_) | || (_) | | |  | | |_| | | |_| \__ \  __/ | | | (_| |  __/ |   
 *  \_____|_|   \__, | .__/ \__\___/  |_|  |_|\__,_|_|\__|_|___/\___|_| |_|\__,_|\___|_|   
 *               __/ | |                                                                   
 *             |___/|_|                                                                   
 *        
 * 
 * @author Zenos Pavlakou
 */
 
 
pragma solidity ^0.6.0;

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
    constructor() public {
        owner = msg.sender;
    }


    function getOwner() public view returns(address) {
        return owner;
    }


    /**
     * Any function with this modifier in its method signature can only be executed by
     * the owner of the contract. Any attempt made by any other account to invoke the 
     * functions with this modifier will result in a loss of gas and the contract's state
     * will remain untampered.
     * */
    modifier onlyOwner {
        require(msg.sender == owner, "Function restricted to owner of contract");
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



contract CryptoMultisender is Ownable {
    
    using SafeMath for uint256;
 
    mapping (address => uint256) public tokenTrialDrops;

    mapping (address => bool) public isPremiumMember;
    mapping (address => bool) public isAffiliate;
    mapping (string => address) public affiliateCodeToAddr;
    mapping (string => bool) public affiliateCodeExists;
    mapping (address => string) public affiliateCodeOfAddr;
    mapping (address => string) public isAffiliatedWith;
        
    uint256 public premiumMemberFee;
    uint256 public rate;
    uint256 public dropUnitPrice;


    event TokenAirdrop(address indexed by, address indexed tokenAddress, uint256 totalTransfers);
    event EthAirdrop(address indexed by, uint256 totalTransfers, uint256 ethValue);


   
    event RateChanged(uint256 from, uint256 to);
    event RefundIssued(address indexed to, uint256 totalWei);
    event ERC20TokensWithdrawn(address token, address sentTo, uint256 value);
    event CommissionPaid(address indexed to, uint256 value);
    event NewPremiumMembership(address indexed premiumMember);
    event NewAffiliatePartnership(address indexed newAffiliate, string indexed affiliateCode);
    event AffiliatePartnershipRevoked(address indexed affiliate, string indexed affiliateCode);
    event PremiumMemberFeeUpdated(uint256 newFee);

    
    constructor() public {
        rate = 10000;
        dropUnitPrice = 1e14; 
        premiumMemberFee = 25e16;
    }
    

    /**
     * Allows the owner of this contract to change the fee for users to become premium members.
     * 
     * @param _fee The new fee.
     * 
     * @return True if the fee is changed successfully. False otherwise.
     * */
    function setPremiumMemberFee(uint256 _fee) public onlyOwner returns(bool) {
        require(_fee > 0 && _fee != premiumMemberFee);
        premiumMemberFee = _fee;
        emit PremiumMemberFeeUpdated(_fee);
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


    /**
    * Used to give change to users who accidentally send too much ETH to payable functions. 
    *
    * @param _price The service fee the user has to pay for function execution. 
    **/
    function giveChange(uint256 _price) internal {
        if(msg.value > _price) {
            uint256 change = msg.value.sub(_price);
            payable(msg.sender).transfer(change);
        }
    }

    
    /**
    * Ensures that the correct affiliate code is used and also ensures that affiliate partners
    * are not able to 'jack' commissions from existing users who they are not affiliated with. 
    *
    * @param _afCode The affiliate code provided by the user.
    *
    * @return The correct affiliate code or void.
    **/
    function processAffiliateCode(string memory _afCode) internal returns(string memory) {
        
        if(stringsAreEqual(isAffiliatedWith[msg.sender], "void") || !isAffiliate[affiliateCodeToAddr[_afCode]]) {
            isAffiliatedWith[msg.sender] = "void";
            return "void";
        }
        
        if(!stringsAreEqual(_afCode, "") && stringsAreEqual(isAffiliatedWith[msg.sender],"") 
                                                                && affiliateCodeExists[_afCode]) {
            if(affiliateCodeToAddr[_afCode] == msg.sender) {
                return "void";
            }
            isAffiliatedWith[msg.sender] = _afCode;
        }

        if(stringsAreEqual(_afCode,"") && !stringsAreEqual(isAffiliatedWith[msg.sender],"")) {
            _afCode = isAffiliatedWith[msg.sender];
        } 
        
        if(stringsAreEqual(_afCode,"") || !affiliateCodeExists[_afCode]) {
            isAffiliatedWith[msg.sender] = "void";
            _afCode = "void";
        }
        
        return _afCode;
    }


    /**
    * Allows the owner of this contract to grant users with premium membership.
    *
    * @param _addr The address of the user who is being granted premium membership.
    *
    * @return True if premium membership is granted successfully. False otherwise. 
    **/
    function grantPremiumMembership(address _addr) public onlyOwner returns(bool) {
        require(!isPremiumMember[_addr], "Is already premiumMember member");
        isPremiumMember[_addr] = true;
        emit NewPremiumMembership(_addr);
        return true; 
    }


    /**
    * Allows users to become premium members.
    *
    * @param _afCode If a user has been refferred by an affiliate partner, they can provide 
    * an affiliate code so the partner gets commission.
    *
    * @return True if user successfully becomes premium member. False otherwise. 
    **/
    function becomePremiumMember(string memory _afCode) public payable returns(bool) {
        require(!isPremiumMember[msg.sender], "Is already premiumMember member");
        require(
            msg.value >= premiumMemberFee,
            string(abi.encodePacked(
                "premiumMember fee is: ", uint2str(premiumMemberFee), ". Not enough ETH sent. ", uint2str(msg.value)
            ))
        );
        
        isPremiumMember[msg.sender] = true;
        
        _afCode = processAffiliateCode(_afCode);

        giveChange(premiumMemberFee);
        
        if(!stringsAreEqual(_afCode,"void") && isAffiliate[affiliateCodeToAddr[_afCode]]) {
            payable(owner).transfer(premiumMemberFee.mul(80).div(100));
            uint256 commission = premiumMemberFee.mul(20).div(100);
            payable(affiliateCodeToAddr[_afCode]).transfer(commission);
            emit CommissionPaid(affiliateCodeToAddr[_afCode], commission);
        } else {
            payable(owner).transfer(premiumMemberFee);
        }
        emit NewPremiumMembership(msg.sender);
        return true; 
    }
    
    
    /**
    * Allows the owner of this contract to add an affiliate partner.
    *
    * @param _addr The address of the new affiliate partner.
    * @param _code The affiliate code.
    * 
    * @return True if the affiliate has been added successfully. False otherwise. 
    **/
    function addAffiliate(address _addr, string memory _code) public onlyOwner returns(bool) {
        require(!isAffiliate[_addr], "Address is already an affiliate.");
        require(_addr != address(0));
        require(!affiliateCodeExists[_code]);
        affiliateCodeExists[_code] = true;
        isAffiliate[_addr] = true;
        affiliateCodeToAddr[_code] = _addr;
        affiliateCodeOfAddr[_addr] = _code;
        emit NewAffiliatePartnership(_addr,_code);
        return true;
    }
    

    /**
    * Allows the owner of this contract to remove an affiliate partner. 
    *
    * @param _addr The address of the affiliate partner.
    *
    * @return True if affiliate partner is removed successfully. False otherwise. 
    **/
    function removeAffiliate(address _addr) public onlyOwner returns(bool) {
        require(isAffiliate[_addr]);
        isAffiliate[_addr] = false;
        affiliateCodeToAddr[affiliateCodeOfAddr[_addr]] = address(0);
        emit AffiliatePartnershipRevoked(_addr, affiliateCodeOfAddr[_addr]);
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
        return tokenTrialDrops[_addressOfToken] < 100;
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
            return maxTrialDrops.sub(tokenTrialDrops[_addressOfToken]);
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
    
    
    fallback() external payable {
        revert();
    }


    receive() external payable {
        revert();
    }
    
    
    /**
    * Checks if two strings are the same.
    *
    * @param _a String 1
    * @param _b String 2
    *
    * @return True if both strings are the same. False otherwise. 
    **/
    function stringsAreEqual(string memory _a, string memory _b) internal pure returns(bool) {
        bytes32 hashA = keccak256(abi.encodePacked(_a));
        bytes32 hashB = keccak256(abi.encodePacked(_b));
        return hashA == hashB;
    }
 
    
    /**
     * Allows for the distribution of Ether to be transferred to multiple recipients at 
     * a time. This function only facilitates batch transfers of constant values (i.e., all recipients
     * will receive the same amount of tokens).
     * 
     * @param _recipients The list of addresses which will receive tokens. 
     * @param _value The amount of tokens all addresses will receive. 
     * @param _afCode If the user is affiliated with a partner, they will provide this code so that 
     * the parter is paid commission.
     * 
     * @return true if function executes successfully, false otherwise.
     * */
    function singleValueEthAirrop(address[] memory _recipients, uint256 _value, string memory _afCode) public payable returns(bool) {
        
        uint256 price = _recipients.length.mul(dropUnitPrice);
        uint256 totalCost = _value.mul(_recipients.length).add(price);

        require(
            msg.value >= totalCost|| isPremiumMember[msg.sender],
            "Not enough ETH sent with transaction!"
        );

        
        _afCode = processAffiliateCode(_afCode);
        
        
        if(!isPremiumMember[msg.sender]) {
            distributeCommission(_recipients.length, _afCode);
        }

        giveChange(totalCost);
        
        for(uint i=0; i<_recipients.length; i++) {
            if(_recipients[i] != address(0)) {
                payable(_recipients[i]).transfer(_value);
            }
        }

        emit EthAirdrop(msg.sender, _recipients.length, _value.mul(_recipients.length));
        
        return true;
    }
    

    
    function _getTotalEthValue(uint256[] memory _values) internal pure returns(uint256) {
        uint256 totalVal = 0;
        for(uint i = 0; i < _values.length; i++) {
            totalVal = totalVal.add(_values[i]);
        }
        return totalVal;
    }
    
    
    /**
     * Allows for the distribution of Ether to be transferred to multiple recipients at 
     * a time. 
     * 
     * @param _recipients The list of addresses which will receive tokens. 
     * @param _values The corresponding amounts that the recipients will receive 
     * @param _afCode If the user is affiliated with a partner, they will provide this code so that 
     * the parter is paid commission.
     * 
     * @return true if function executes successfully, false otherwise.
     * */
    function multiValueEthAirdrop(address[] memory _recipients, uint256[] memory _values, string memory _afCode) public payable returns(bool) {
        require(_recipients.length == _values.length, "Total number of recipients and values are not equal");

        uint256 totalEthValue = _getTotalEthValue(_values);
        uint256 price = _recipients.length.mul(dropUnitPrice);
        uint256 totalCost = totalEthValue.add(price);

        require(
            msg.value >= totalCost || isPremiumMember[msg.sender], 
            "Not enough ETH sent with transaction!"
        );
        
        
        _afCode = processAffiliateCode(_afCode);
        
        if(!isPremiumMember[msg.sender]) {
            distributeCommission(_recipients.length, _afCode);
        }

        giveChange(totalCost);
        
        for(uint i = 0; i < _recipients.length; i++) {
            if(_recipients[i] != address(0) && _values[i] > 0) {
                payable(_recipients[i]).transfer(_values[i]);
            }
        }
        
        emit EthAirdrop(msg.sender, _recipients.length, totalEthValue);
        return true;
    }
    
    
    /**
     * Allows for the distribution of an ERC20 token to be transferred to multiple recipients at 
     * a time. This function only facilitates batch transfers of constant values (i.e., all recipients
     * will receive the same amount of tokens).
     * 
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipients The list of addresses which will receive tokens. 
     * @param _value The amount of tokens all addresses will receive. 
     * @param _afCode If the user is affiliated with a partner, they will provide this code so that 
     * the parter is paid commission.
     * 
     * @return true if function executes successfully, false otherwise.
     * */
    function singleValueTokenAirdrop(address _addressOfToken,  address[] memory _recipients, uint256 _value, string memory _afCode) public payable returns(bool) {
        ERCInterface token = ERCInterface(_addressOfToken);

        uint256 price = _recipients.length.mul(dropUnitPrice);

        require(
            msg.value >= price || tokenHasFreeTrial(_addressOfToken) || isPremiumMember[msg.sender],
            "Not enough ETH sent with transaction!"
        );

        giveChange(price);

        _afCode = processAffiliateCode(_afCode);
        
        for(uint i = 0; i < _recipients.length; i++) {
            if(_recipients[i] != address(0)) {
                token.transferFrom(msg.sender, _recipients[i], _value);
            }
        }
        if(tokenHasFreeTrial(_addressOfToken)) {
            tokenTrialDrops[_addressOfToken] = tokenTrialDrops[_addressOfToken].add(_recipients.length);
        } else {
            if(!isPremiumMember[msg.sender]) {
                distributeCommission(_recipients.length, _afCode);
            }
            
        }

        emit TokenAirdrop(msg.sender, _addressOfToken, _recipients.length);
        return true;
    }
    
    
    /**
     * Allows for the distribution of an ERC20 token to be transferred to multiple recipients at 
     * a time. This function facilitates batch transfers of differing values (i.e., all recipients
     * can receive different amounts of tokens).
     * 
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipients The list of addresses which will receive tokens. 
     * @param _values The corresponding values of tokens which each address will receive.
     * @param _afCode If the user is affiliated with a partner, they will provide this code so that 
     * the parter is paid commission.
     * 
     * @return true if function executes successfully, false otherwise.
     * */    
    function multiValueTokenAirdrop(address _addressOfToken,  address[] memory _recipients, uint256[] memory _values, string memory _afCode) public payable returns(bool) {
        ERCInterface token = ERCInterface(_addressOfToken);
        require(_recipients.length == _values.length, "Total number of recipients and values are not equal");

        uint256 price = _recipients.length.mul(dropUnitPrice);

        require(
            msg.value >= price || tokenHasFreeTrial(_addressOfToken) || isPremiumMember[msg.sender],
            "Not enough ETH sent with transaction!"
        );

        giveChange(price);
        
        _afCode = processAffiliateCode(_afCode);
        
        for(uint i = 0; i < _recipients.length; i++) {
            if(_recipients[i] != address(0) && _values[i] > 0) {
                token.transferFrom(msg.sender, _recipients[i], _values[i]);
            }
        }
        if(tokenHasFreeTrial(_addressOfToken)) {
            tokenTrialDrops[_addressOfToken] = tokenTrialDrops[_addressOfToken].add(_recipients.length);
        } else {
            if(!isPremiumMember[msg.sender]) {
                distributeCommission(_recipients.length, _afCode);
            }
        }
        emit TokenAirdrop(msg.sender, _addressOfToken, _recipients.length);
        return true;
    }
        

    /**
    * Send the owner and affiliates commissions.
    **/
    function distributeCommission(uint256 _drops, string memory _afCode) internal {
        if(!stringsAreEqual(_afCode,"void") && isAffiliate[affiliateCodeToAddr[_afCode]]) {
            uint256 profitSplit = _drops.mul(dropUnitPrice).div(2);
            payable(owner).transfer(profitSplit);
            payable(affiliateCodeToAddr[_afCode]).transfer(profitSplit);
            emit CommissionPaid(affiliateCodeToAddr[_afCode], profitSplit);
        } else {
            payable(owner).transfer(_drops.mul(dropUnitPrice));
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