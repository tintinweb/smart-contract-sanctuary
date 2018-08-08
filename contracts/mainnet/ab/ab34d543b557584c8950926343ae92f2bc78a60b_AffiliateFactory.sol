pragma solidity ^0.4.21;


  /**
   * @title SafeMath
   * @dev Math operations with safety checks that throw on error
   */
  library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
      // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
      c = a + b;
      assert(c >= a);
      return c;
    }
  }

  contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
  }

  contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
  }

  contract WETH9 {
      string public name     = "Wrapped Ether";
      string public symbol   = "WETH";
      uint8  public decimals = 18;

      event  Approval(address indexed src, address indexed guy, uint wad);
      event  Transfer(address indexed src, address indexed dst, uint wad);
      event  Deposit(address indexed dst, uint wad);
      event  Withdrawal(address indexed src, uint wad);

      mapping (address => uint)                       public  balanceOf;
      mapping (address => mapping (address => uint))  public  allowance;

      function() public payable {
          deposit();
      }
      function deposit() public payable {
          balanceOf[msg.sender] += msg.value;
          Deposit(msg.sender, msg.value);
      }
      function withdraw(uint wad) public {
          require(balanceOf[msg.sender] >= wad);
          balanceOf[msg.sender] -= wad;
          msg.sender.transfer(wad);
          Withdrawal(msg.sender, wad);
      }

      function totalSupply() public view returns (uint) {
          return this.balance;
      }

      function approve(address guy, uint wad) public returns (bool) {
          allowance[msg.sender][guy] = wad;
          Approval(msg.sender, guy, wad);
          return true;
      }

      function transfer(address dst, uint wad) public returns (bool) {
          return transferFrom(msg.sender, dst, wad);
      }

      function transferFrom(address src, address dst, uint wad)
          public
          returns (bool)
      {
          require(balanceOf[src] >= wad);

          if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
              require(allowance[src][msg.sender] >= wad);
              allowance[src][msg.sender] -= wad;
          }

          balanceOf[src] -= wad;
          balanceOf[dst] += wad;

          Transfer(src, dst, wad);

          return true;
      }
  }


  interface Registry {
      function isAffiliated(address _affiliate) external returns (bool);
  }

  contract Affiliate {
    struct Share {
        address shareholder;
        uint stake;
    }

    Share[] shares;
    uint public totalShares;
    string public relayerName;
    address registry;
    WETH9 weth;

    event Payout(address indexed token, uint amount);

    function init(address _registry, address[] shareholders, uint[] stakes, address _weth, string _name) public returns (bool) {
      require(totalShares == 0);
      require(shareholders.length == stakes.length);
      weth = WETH9(_weth);
      totalShares = 0;
      for(uint i=0; i < shareholders.length; i++) {
          shares.push(Share({shareholder: shareholders[i], stake: stakes[i]}));
          totalShares += stakes[i];
      }
      relayerName = _name;
      registry = _registry;
      return true;
    }
    function payout(address[] tokens) public {
        // Payout all stakes at once, so we don&#39;t have to do bookkeeping on who has
        // claimed their shares and who hasn&#39;t. If the number of shareholders is large
        // this could run into some gas limits. In most cases, I expect two
        // shareholders, but it could be a small handful. This also means the caller
        // must pay gas for everyone&#39;s payouts.
        for(uint i=0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            uint balance = token.balanceOf(this);
            for(uint j=0; j < shares.length; j++) {
                token.transfer(shares[j].shareholder, SafeMath.mul(balance, shares[j].stake) / totalShares);
            }
            emit Payout(tokens[i], balance);
        }
    }
    function isAffiliated(address _affiliate) public returns (bool)
    {
        return Registry(registry).isAffiliated(_affiliate);
    }

    function() public payable {
      // If we get paid in ETH, convert to WETH so payouts work the same.
      // Converting to WETH also makes payouts a bit safer, as we don&#39;t have to
      // worry about code execution if the stakeholder is a contract.
      weth.deposit.value(msg.value)();
    }

  }



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
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }

  }

  interface Downstream {
      function registerAffiliate(address _affiliate, string _name) external returns (bool);
  }

  contract AffiliateFactory is Ownable {

      event AffiliateDeployed(address affiliateAddress, address targetAddress, string affiliateName, address indexed sender);

      address public target;
      address public beneficiary;
      address public WETH;
      address public downstream;
      uint public beneficiaryStake;
      uint public senderStake;
      mapping(address => string) affiliates;

      constructor(address _target, address _weth, uint _beneficiaryStake, uint _senderStake, address _downstream) public Ownable() {
         update(_target, msg.sender, _weth, _beneficiaryStake, _senderStake, _downstream);
      }

      function update(address _target, address _beneficiary, address _weth, uint _beneficiaryStake, uint _senderStake, address _downstream) public onlyOwner {
          target = _target;
          beneficiary = _beneficiary;
          beneficiaryStake = _beneficiaryStake;
          senderStake = _senderStake;
          downstream = _downstream;
          WETH = _weth;
      }

      function signUp(address[] _stakeHolders, uint256[] _stakes, string _name)
          external
          returns (address affiliateContract)
      {
          require(_stakeHolders.length > 0 && _stakeHolders.length == _stakes.length && bytes(_name).length > 0);
          affiliateContract = createProxyImpl(target);
          address[] memory stakeHolders = new address[](_stakeHolders.length + 1);
          uint[] memory shares = new uint[](stakeHolders.length);
          stakeHolders[0] = beneficiary;
          shares[0] = beneficiaryStake;
          uint256 stakesTotal = 0;

          for(uint i=0; i < _stakeHolders.length; i++) {
            require(_stakes[i] > 0);
            stakesTotal = SafeMath.add(stakesTotal, _stakes[i]);
          }
          require(stakesTotal > 0);
          for(i=0; i < _stakeHolders.length; i++) {
            stakeHolders[i+1] = _stakeHolders[i];
            // (user stake) / (total stake) * (available stake) ; but with integer math
            shares[i+1] = SafeMath.mul(_stakes[i], senderStake) / stakesTotal ;
          }
          require(Affiliate(affiliateContract).init(this, stakeHolders, shares, WETH, _name));
          affiliates[affiliateContract] = _name;
          emit AffiliateDeployed(affiliateContract, target, _name, msg.sender);
          if(downstream != address(0)) {
            Downstream(downstream).registerAffiliate(affiliateContract, _name);
          }
      }

      function registerAffiliate(address[] stakeHolders, uint[] shares, string _name)
          external
          onlyOwner
          returns (address affiliateContract)
      {
          require(stakeHolders.length > 0 && stakeHolders.length == shares.length && bytes(_name).length > 0);
          affiliateContract = createProxyImpl(target);
          require(Affiliate(affiliateContract).init(this, stakeHolders, shares, WETH, _name));
          affiliates[affiliateContract] = _name;
          emit AffiliateDeployed(affiliateContract, target, _name, msg.sender);
          if(downstream != address(0)) {
            Downstream(downstream).registerAffiliate(affiliateContract, _name);
          }
      }

      function isAffiliated(address _affiliate) external view returns (bool)
      {
        return bytes(affiliates[_affiliate]).length != 0;
      }

      function affiliateName(address _affiliate) external view returns (string)
      {
        return affiliates[_affiliate];
      }

      function createProxyImpl(address _target)
          internal
          returns (address proxyContract)
      {
          assembly {
              let contractCode := mload(0x40) // Find empty storage location using "free memory pointer"

              mstore(add(contractCode, 0x0b), _target) // Add target address, with a 11 bytes [i.e. 23 - (32 - 20)] offset to later accomodate first part of the bytecode
              mstore(sub(contractCode, 0x09), 0x000000000000000000603160008181600b9039f3600080808080368092803773) // First part of the bytecode, shifted left by 9 bytes, overwrites left padding of target address
              mstore(add(contractCode, 0x2b), 0x5af43d828181803e808314602f57f35bfd000000000000000000000000000000) // Final part of bytecode, offset by 43 bytes

              proxyContract := create(0, contractCode, 60) // total length 60 bytes
              if iszero(extcodesize(proxyContract)) {
                  revert(0, 0)
              }
          }
      }
  }