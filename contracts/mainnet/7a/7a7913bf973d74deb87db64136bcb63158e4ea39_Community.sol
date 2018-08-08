// compiler: 0.4.20+commit.3155dd80.Emscripten.clang
pragma solidity ^0.4.20;

contract owned {
  address public owner;

  function owned() public {
    owner = msg.sender;
  }

  function changeOwner( address newowner ) public onlyOwner {
    owner = newowner;
  }

  modifier onlyOwner {
    if (msg.sender != owner) { revert(); }
    _;
  }
}

contract Community is owned {

  event Receipt( address indexed sender, uint value );

  string  public name_; // "IT", "KO", ...
  address public manager_;
  uint    public bonus_;
  uint    public start_;
  uint    public end_;

  function Community() public {}

  function setName( string _name ) public onlyOwner {
    name_ = _name;
  }

  function setManager( address _mgr ) public onlyOwner {
    manager_ = _mgr;
  }

  function setBonus( uint _bonus ) public onlyOwner {
    bonus_ = _bonus;
  }

  function setTimes( uint _start, uint _end ) public onlyOwner {
    require( _end > _start );

    start_ = _start;
    end_ = _end;
  }

  // set gas limit to something greater than 24073
  function() public payable {
    require( now >= start_ && now <= end_ );

    owner.transfer( msg.value );

    Receipt( msg.sender, msg.value );
  }
}