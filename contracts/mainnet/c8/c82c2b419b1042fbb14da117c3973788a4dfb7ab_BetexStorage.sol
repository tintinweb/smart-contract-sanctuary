pragma solidity ^0.4.21;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title BetexStorage
 */
contract BetexStorage is Ownable {

    // minimum funding to get volume bonus	
    uint256 public constant VOLUME_BONUS_CONDITION = 50 ether;

    // minimum funding to get volume extra bonus	
    uint256 public constant VOLUME_EXTRA_BONUS_CONDITION = 100 ether;

    // extra bonus amount during first bonus round, %
    uint256 public constant FIRST_VOLUME_EXTRA_BONUS = 20;

    // extra bonus amount during second bonus round, %
    uint256 public constant SECOND_VOLUME_EXTRA_BONUS = 10;

    // bonus amount during first bonus round, %
    uint256 public constant FIRST_VOLUME_BONUS = 10;

    // bonus amount during second bonus round, %
    uint256 public constant SECOND_VOLUME_BONUS = 5;

    // oraclize funding order
    struct Order {
        address beneficiary;
        uint256 funds;
        uint256 bonus;
        uint256 rate;
    }

    // oraclize funding orders
    mapping (bytes32 => Order) public orders;

    // oraclize orders for unsold tokens allocation
    mapping (bytes32 => bool) public unsoldAllocationOrders;

    // addresses allowed to buy tokens
    mapping (address => bool) public whitelist;

    // funded
    mapping (address => bool) public funded;

    // funders
    address[] public funders;
    
    // pre ico funders
    address[] public preICOFunders;

    // tokens to allocate before ico sale starts
    mapping (address => uint256) public preICOBalances;

    // is preICO data initialized
    bool public preICODataInitialized;


    /**
     * @dev Constructor
     */  
    function BetexStorage() public {

        // pre sale round 1
        preICOFunders.push(0x233Fd2B3d7a0924Fe1Bb0dd7FA168eEF8C522E65);
        preICOBalances[0x233Fd2B3d7a0924Fe1Bb0dd7FA168eEF8C522E65] = 15000000000000000000000;
        preICOFunders.push(0x2712ba56cB3Cf8783693c8a1796F70ABa57132b1);
        preICOBalances[0x2712ba56cB3Cf8783693c8a1796F70ABa57132b1] = 15000000000000000000000;
        preICOFunders.push(0x6f3DDfb726eA637e125C4fbf6694B940711478f4);
        preICOBalances[0x6f3DDfb726eA637e125C4fbf6694B940711478f4] = 15000000000000000000000;
        preICOFunders.push(0xAf7Ff6f381684707001d517Bf83C4a3538f9C82a);
        preICOBalances[0xAf7Ff6f381684707001d517Bf83C4a3538f9C82a] = 22548265874120000000000;
        preICOFunders.push(0x51219a9330c196b8bd7fA0737C8e0db53c1ad628);
        preICOBalances[0x51219a9330c196b8bd7fA0737C8e0db53c1ad628] = 32145215844400000000000;
        preICOFunders.push(0xA2D42D689769f7BA32712f27B09606fFD8F3b699);
        preICOBalances[0xA2D42D689769f7BA32712f27B09606fFD8F3b699] = 15000000000000000000000;
        preICOFunders.push(0xB7C9D3AAbF44296232538B8b184F274B57003994);
        preICOBalances[0xB7C9D3AAbF44296232538B8b184F274B57003994] = 20000000000000000000000;
        preICOFunders.push(0x58667a170F53b809CA9143c1CeEa00D2Df866577);
        preICOBalances[0x58667a170F53b809CA9143c1CeEa00D2Df866577] = 184526257787000000000000;
        preICOFunders.push(0x0D4b2A1a47b1059d622C033c2a58F2F651010553);
        preICOBalances[0x0D4b2A1a47b1059d622C033c2a58F2F651010553] = 17845264771100000000000;
        preICOFunders.push(0x982F59497026473d2227f5dd02cdf6fdCF237AE0);
        preICOBalances[0x982F59497026473d2227f5dd02cdf6fdCF237AE0] = 31358989521120000000000;
        preICOFunders.push(0x250d540EFeabA7b5C0407A955Fd76217590dbc37);
        preICOBalances[0x250d540EFeabA7b5C0407A955Fd76217590dbc37] = 15000000000000000000000;
        preICOFunders.push(0x2Cde7768B7d5dcb12c5b5572daEf3F7B855c8685);
        preICOBalances[0x2Cde7768B7d5dcb12c5b5572daEf3F7B855c8685] = 17500000000000000000000;
        preICOFunders.push(0x89777c2a4C1843a99B2fF481a4CEF67f5d7A1387);
        preICOBalances[0x89777c2a4C1843a99B2fF481a4CEF67f5d7A1387] = 15000000000000000000000;
        preICOFunders.push(0x63699D4d309e48e8B575BE771700570A828dC655);
        preICOBalances[0x63699D4d309e48e8B575BE771700570A828dC655] = 15000000000000000000000;
        preICOFunders.push(0x9bc92E0da2e4aC174b8E33D7c74b5009563a8e2A);
        preICOBalances[0x9bc92E0da2e4aC174b8E33D7c74b5009563a8e2A] = 21542365440880000000000;
        preICOFunders.push(0xA1CA632CF8Fb3a965c84668e09e3BEdb3567F35D);
        preICOBalances[0xA1CA632CF8Fb3a965c84668e09e3BEdb3567F35D] = 15000000000000000000000;
        preICOFunders.push(0x1DCeF74ddD26c82f34B300E027b5CaA4eC4F8C83);
        preICOBalances[0x1DCeF74ddD26c82f34B300E027b5CaA4eC4F8C83] = 15000000000000000000000;
        preICOFunders.push(0x51B7Bf4B7C1E89cfe7C09938Ad0096F9dFFCA4B7);
        preICOBalances[0x51B7Bf4B7C1E89cfe7C09938Ad0096F9dFFCA4B7] = 17533640761380000000000;

        // pre sale round 2 
        preICOFunders.push(0xD2Cdc0905877ee3b7d08220D783bd042de825AEb);
        preICOBalances[0xD2Cdc0905877ee3b7d08220D783bd042de825AEb] = 5000000000000000000000;
        preICOFunders.push(0x3b217081702AF670e2c2fD25FD7da882620a68E8);
        preICOBalances[0x3b217081702AF670e2c2fD25FD7da882620a68E8] = 7415245400000000000000;
        preICOFunders.push(0xbA860D4B9423bF6b517B29c395A49fe80Da758E3);
        preICOBalances[0xbA860D4B9423bF6b517B29c395A49fe80Da758E3] = 5000000000000000000000;
        preICOFunders.push(0xF64b80DdfB860C0D1bEb760fd9fC663c4D5C4dC3);
        preICOBalances[0xF64b80DdfB860C0D1bEb760fd9fC663c4D5C4dC3] = 75000000000000000000000;
        preICOFunders.push(0x396D5A35B5f41D7cafCCF9BeF225c274d2c7B6E2);
        preICOBalances[0x396D5A35B5f41D7cafCCF9BeF225c274d2c7B6E2] = 74589245777000000000000;
        preICOFunders.push(0x4d61A4aD175E96139Ae8c5d951327e3f6Cc3f764);
        preICOBalances[0x4d61A4aD175E96139Ae8c5d951327e3f6Cc3f764] = 5000000000000000000000;
        preICOFunders.push(0x4B490F6A49C17657A5508B8Bf8F1D7f5aAD8c921);
        preICOBalances[0x4B490F6A49C17657A5508B8Bf8F1D7f5aAD8c921] = 200000000000000000000000;
        preICOFunders.push(0xC943038f2f1dd1faC6E10B82039C14bd20ff1F8E);
        preICOBalances[0xC943038f2f1dd1faC6E10B82039C14bd20ff1F8E] = 174522545811300000000000;
        preICOFunders.push(0xBa87D63A8C4Ed665b6881BaCe4A225a07c418F22);
        preICOBalances[0xBa87D63A8C4Ed665b6881BaCe4A225a07c418F22] = 5000000000000000000000;
        preICOFunders.push(0x753846c0467cF320BcDA9f1C67fF86dF39b1438c);
        preICOBalances[0x753846c0467cF320BcDA9f1C67fF86dF39b1438c] = 5000000000000000000000;
        preICOFunders.push(0x3773bBB1adDF9D642D5bbFaafa13b0690Fb33460);
        preICOBalances[0x3773bBB1adDF9D642D5bbFaafa13b0690Fb33460] = 5000000000000000000000;
        preICOFunders.push(0x456Cf70345cbF483779166af117B40938B8F0A9c);
        preICOBalances[0x456Cf70345cbF483779166af117B40938B8F0A9c] = 50000000000000000000000;
        preICOFunders.push(0x662AE260D736F041Db66c34617d5fB22eC0cC2Ee);
        preICOBalances[0x662AE260D736F041Db66c34617d5fB22eC0cC2Ee] = 40000000000000000000000;
        preICOFunders.push(0xEa7e647F167AdAa4df52AF630A873a1379f68E3F);
        preICOBalances[0xEa7e647F167AdAa4df52AF630A873a1379f68E3F] = 40000000000000000000000;
        preICOFunders.push(0x352913f3F7CA96530180b93C18C86f38b3F0c429);
        preICOBalances[0x352913f3F7CA96530180b93C18C86f38b3F0c429] = 45458265454000000000000;
        preICOFunders.push(0xB21bf8391a6500ED210Af96d125867124261f4d4);
        preICOBalances[0xB21bf8391a6500ED210Af96d125867124261f4d4] = 5000000000000000000000;
        preICOFunders.push(0xDecBd29B42c66f90679D2CB34e73E571F447f6c5);
        preICOBalances[0xDecBd29B42c66f90679D2CB34e73E571F447f6c5] = 7500000000000000000000;
        preICOFunders.push(0xE36106a0DC0F07e87f7194694631511317909b8B);
        preICOBalances[0xE36106a0DC0F07e87f7194694631511317909b8B] = 5000000000000000000000;
        preICOFunders.push(0xe9114cd97E0Ee4fe349D3F57d0C9710E18581b69);
        preICOBalances[0xe9114cd97E0Ee4fe349D3F57d0C9710E18581b69] = 40000000000000000000000;
        preICOFunders.push(0xC73996ce45752B9AE4e85EDDf056Aa9aaCaAD4A2);
        preICOBalances[0xC73996ce45752B9AE4e85EDDf056Aa9aaCaAD4A2] = 100000000000000000000000;
        preICOFunders.push(0x6C1407d9984Dc2cE33456b67acAaEC78c1784673);
        preICOBalances[0x6C1407d9984Dc2cE33456b67acAaEC78c1784673] = 5000000000000000000000;
        preICOFunders.push(0x987e93429004CA9fa2A42604658B99Bb5A574f01);
        preICOBalances[0x987e93429004CA9fa2A42604658B99Bb5A574f01] = 124354548881022000000000;
        preICOFunders.push(0x4c3B81B5f9f9c7efa03bE39218E6760E8D2A1609);
        preICOBalances[0x4c3B81B5f9f9c7efa03bE39218E6760E8D2A1609] = 5000000000000000000000;
        preICOFunders.push(0x33fA8cd89B151458Cb147ecC497e469f2c1D38eA);
        preICOBalances[0x33fA8cd89B151458Cb147ecC497e469f2c1D38eA] = 60000000000000000000000;

        // main sale (01-31 of Marh)
        preICOFunders.push(0x9AfA1204afCf48AB4302F246Ef4BE5C1D733a751);
        preICOBalances[0x9AfA1204afCf48AB4302F246Ef4BE5C1D733a751] = 154551417972192330000000;
    }

    /**
     * @dev Add a new address to the funders
     * @param _funder funder&#39;s address
     */
    function addFunder(address _funder) public onlyOwner {
        if (!funded[_funder]) {
            funders.push(_funder);
            funded[_funder] = true;
        }
    }
   
    /**
     * @return true if address is a funder address
     * @param _funder funder&#39;s address
     */
    function isFunder(address _funder) public view returns(bool) {
        return funded[_funder];
    }

    /**
     * @return funders count
     */
    function getFundersCount() public view returns(uint256) {
        return funders.length;
    }

    /**
     * @return number of preICO funders count
     */
    function getPreICOFundersCount() public view returns(uint256) {
        return preICOFunders.length;
    }

    /**
     * @dev Add a new oraclize funding order
     * @param _orderId oraclize order id
     * @param _beneficiary who&#39;ll get the tokens
     * @param _funds paid wei amount
     * @param _bonus bonus amount
     */
    function addOrder(
        bytes32 _orderId, 
        address _beneficiary, 
        uint256 _funds, 
        uint256 _bonus
    )
        public 
        onlyOwner 
    {
        orders[_orderId].beneficiary = _beneficiary;
        orders[_orderId].funds = _funds;
        orders[_orderId].bonus = _bonus;
    }

    /**
     * @dev Get oraclize funding order by order id
     * @param _orderId oraclize order id
     * @return beneficiaty address, paid funds amount and bonus amount 
     */
    function getOrder(bytes32 _orderId) 
        public 
        view 
        returns(address, uint256, uint256)
    {
        address _beneficiary = orders[_orderId].beneficiary;
        uint256 _funds = orders[_orderId].funds;
        uint256 _bonus = orders[_orderId].bonus;

        return (_beneficiary, _funds, _bonus);
    }

    /**
     * @dev Set eth/usd rate for the specified oraclize order
     * @param _orderId oraclize order id
     * @param _rate eth/usd rate
     */
    function setRateForOrder(bytes32 _orderId, uint256 _rate) public onlyOwner {
        orders[_orderId].rate = _rate;
    }

    /**
     * @dev Add a new oraclize unsold tokens allocation order
     * @param _orderId oraclize order id
     */
    function addUnsoldAllocationOrder(bytes32 _orderId) public onlyOwner {
        unsoldAllocationOrders[_orderId] = true;
    }

    /**
     * @dev Whitelist the address
     * @param _address address to be whitelisted
     */
    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    /**
     * @dev Check if address is whitelisted
     * @param _address address that needs to be verified
     * @return true if address is whitelisted
     */
    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }

    /**
     * @dev Get bonus amount for token purchase
     * @param _funds amount of the funds
     * @param _bonusChangeTime bonus change time
     * @return corresponding bonus value
     */
    function getBonus(uint256 _funds, uint256 _bonusChangeTime) public view returns(uint256) {
        
        if (_funds < VOLUME_BONUS_CONDITION)
            return 0;

        if (now < _bonusChangeTime) { // solium-disable-line security/no-block-members
            if (_funds >= VOLUME_EXTRA_BONUS_CONDITION)
                return FIRST_VOLUME_EXTRA_BONUS;
            else 
                return FIRST_VOLUME_BONUS;
        } else {
            if (_funds >= VOLUME_EXTRA_BONUS_CONDITION)
                return SECOND_VOLUME_EXTRA_BONUS;
            else
                return SECOND_VOLUME_BONUS;
        }
        return 0;
    }
}