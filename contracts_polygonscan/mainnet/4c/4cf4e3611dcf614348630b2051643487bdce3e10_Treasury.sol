/**
 *Submitted for verification at polygonscan.com on 2021-11-21
*/

pragma solidity ^0.5.3;

// ---------------------------------------------------------------------------
//  Zdravo Tikvice,nadam se deka ss ovoj ke mozes da priustis srekjan i ubav zivot 
//  nesto sto ne mozese ss mene za zal.
//  Uvek ke sam tuj za tebe i sga i uvek <3
// 
// 
//
// 
// ---------------------------------------------------------------------------

interface Token {
  // note: assume every token implements basic ERC20 transfer function
  function transfer( address to, uint amount ) external;
}

contract owned {
  address public treasurer;

  constructor() public { treasurer = msg.sender; }

  function setTreasurer( address newTreasurer ) public onlyTreasurer
  { treasurer = newTreasurer; }

  modifier onlyTreasurer {
    require( msg.sender == treasurer );
    _;
  }
}

contract Treasury is owned {

  // Events regarding trustees
  event Added( address indexed trustee );
  event Flagged( address indexed trustee, bool isRaised );
  event Replaced( address indexed older, address indexed newer );

  // Events regarding ETH payments ("spends")
  event Proposal( address indexed payee, uint amt, string eref );
  event Approved( address indexed approver,
                  address indexed to,
                  uint amount,
                  string eref );
  event Spent( address indexed payee, uint amt, string eref );

  // Token-related events ("transfers")
  event TransferProposal( address indexed toksca,
                          address indexed to,
                          uint amt,
                          string eref );
  event TransferApproved( address indexed approver,
                          address indexed toksca,
                          address indexed to,
                          uint amount,
                          string eref );
  event Transferred( address indexed toksca,
                     address indexed to,
                     uint amount,
                     string eref );

  // proposals retain approvals in a mapping, the value means:
  // 0 : has not approved (default)
  // 1 : has approved

  struct SpendProp {
    address payee;
    uint    amount;
    string  eref;
    mapping( address => uint8 ) approvals;
    uint    count;
  }

  struct TransferProp {
    address   toksca;
    address   to;
    uint      amount;
    string    eref;
    mapping( address => uint8 ) approvals;
    uint count;
  }

  mapping( bytes32 => SpendProp ) proposals;
  mapping( bytes32 => TransferProp ) tokprops;

  // 0 : not a trustee (default value if querying unrecognized address)
  // 1 : trustee in good standing (flagged == false)
  // 2 : trustee is flagged
  mapping( address => uint8 ) trustees;
  uint trusteeCount;

  constructor() public {}

  function() external payable {}

  function add( address trustee ) public onlyTreasurer {
    require(    trustee != address(0)
             && trustee != treasurer
             && trustees[trustee] == uint8(0) );

    trustees[trustee] = uint8(1);
    trusteeCount++;
    emit Added( trustee );
  }

  function flag( address trustee, bool isRaised ) public onlyTreasurer {
    require( trustees[trustee] != uint8(0) );
    trustees[trustee] = (isRaised) ? uint8(2) : uint8(1);
    emit Flagged( trustee, isRaised );
  }

  function replace( address older, address newer ) public onlyTreasurer {
    require(    trustees[older] != uint8(0)
             && newer != address(0)
             && newer != address(this)
             && newer != treasurer );

    trustees[older] = uint8(0);
    trustees[newer] = uint8(1);
    emit Replaced( older, newer );
  }

  function proposal( address _payee, uint _wei, string memory _eref )
  public onlyTreasurer
  {
    validate( _payee, _wei, _eref );

    bytes32 key = keccak256( abi.encodePacked(_payee, _wei, _eref) );
    proposals[key].payee = _payee;
    proposals[key].amount = _wei;
    proposals[key].eref = _eref;

    emit Proposal( _payee, _wei, _eref );
  }

  function proposeTransfer( address _toksca,
                            address _to,
                            uint _amount,
                            string memory _eref )
  public onlyTreasurer
  {
    validate( _to, _amount, _eref );

    bytes32 key = keccak256( abi.encodePacked(_toksca, _to, _amount, _eref) );
    tokprops[key].toksca = _toksca;
    tokprops[key].to = _to;
    tokprops[key].amount = _amount;
    tokprops[key].eref = _eref;

    emit TransferProposal( _toksca, _to, _amount, _eref );
  }

  function approve( address _payee, uint _wei, string memory _eref ) public
  {
    validate( _payee, _wei, _eref );
    require( trustees[msg.sender] == 1 );

    // fetch matching proposal. if already actioned amount will be zero
    bytes32 key = keccak256( abi.encodePacked(_payee, _wei, _eref) );

    // check proposal exists and not already actioned (amount would be 0)
    require( proposals[key].amount > 0 );

    // prevent voting twice
    if (proposals[key].approvals[msg.sender] != 0)
      revert();

    proposals[key].approvals[msg.sender] = 1;
    proposals[key].count++;
    emit Approved( msg.sender, _payee, _wei, _eref );

    if ( proposals[key].count > (trusteeCount / 2) )
    {
      address payable payee = address(uint160(proposals[key].payee));
      payee.transfer(proposals[key].amount); // throws if error
      proposals[key].amount = 0; // stop double spend
      emit Spent( _payee, _wei, _eref );
    }
  }

  function approveTransfer( address _toksca,
                            address _to,
                            uint    _amount,
                            string  memory _eref ) public
  {
    validate( _to, _amount, _eref );
    bytes32 key = keccak256( abi.encodePacked(_toksca, _to, _amount, _eref) );

    require(    trustees[msg.sender] == uint8(1)
             && tokprops[key].amount > 0 );

    if (tokprops[key].approvals[msg.sender] != 0)
      revert();

    tokprops[key].approvals[msg.sender] = 1;
    tokprops[key].count++;
    emit TransferApproved( msg.sender, _toksca, _to, _amount, _eref );

    if ( tokprops[key].count > (trusteeCount / 2) )
    {
      Token token = Token(_toksca);
      token.transfer( _to, _amount ); // throws on error
      tokprops[key].amount = 0; // prevents double spend
      emit Transferred( _toksca, _to, _amount, _eref );
    }
  }

  function validate( address _to, uint _amount, string memory _eref )
  pure internal
  {
    bytes memory erefb = bytes(_eref);
    require(    _to != address(0)
             && _amount > 0
             && erefb.length > 0
             && erefb.length <= 32 );
  }
}