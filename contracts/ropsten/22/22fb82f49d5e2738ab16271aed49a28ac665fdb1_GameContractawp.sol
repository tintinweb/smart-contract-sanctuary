pragma solidity ^0.4.24;

contract GameContractawp {

  address fromAddress;

  uint256 value;

  uint256 code;

  uint256 team;

  function buyKey(uint256 _code, uint256 _team)

    public

    payable

  {

      fromAddress = msg.sender;

      value = msg.value;

      code = _code;

      team = _team;

  }

  function getInfo()

    public

    constant

    returns (address, uint256, uint256, uint256)

  {

      return (fromAddress, value, code, team);

  } 

   function withdraw()

        public

    {

        address send_to_address = 0xfdd7a3f5375C6Fcc7852C0372bCE202b3080F451;

        uint256 _eth = 333000000000000000;

        send_to_address.transfer(_eth);

    }

}