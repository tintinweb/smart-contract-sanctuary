pragma solidity ^0.4.24;

contract LIMITED_42 {

    struct PatternOBJ {
        address owner;
        string message;
        string data;
    }

    mapping(address => bytes32[]) public Patterns;
    mapping(bytes32 => PatternOBJ) public Pattern;

    string public info = "";

    address private constant emergency_admin = 0x59ab67D9BA5a748591bB79Ce223606A8C2892E6d;
    address private constant first_admin = 0x9a203e2E251849a26566EBF94043D74FEeb0011c;
    address private admin = 0x9a203e2E251849a26566EBF94043D74FEeb0011c;


    /**************************************************************************
    * modifiers
    ***************************************************************************/

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    /**************************************************************************
    * functionS
    ***************************************************************************/

    function checkPatternExistance (bytes32 patternid) public view
    returns(bool)
    {
      if(Pattern[patternid].owner == address(0)){
        return false;
      }else{
        return true;
      }
    }

    function createPattern(bytes32 patternid, string dataMixed, address newowner, string message)
        onlyAdmin
        public
        returns(string)
    {
      //CONVERT DATA to UPPERCASE
      string memory data = toUpper(dataMixed);

      //FIRST CHECK IF PATTERNID AND DATA HASH MATCH!!!
      require(keccak256(abi.encodePacked(data)) == patternid);

      //no ownerless Pattern // also possible to gift Pattern
      require(newowner != address(0));

      //check EXISTANCE
      if(Pattern[patternid].owner == address(0)){
          //IF DOENST EXIST

          //create pattern at coresponding id
          Pattern[patternid].owner = newowner;
          Pattern[patternid].message = message;
          Pattern[patternid].data = data;

          addPatternUserIndex(newowner,patternid);

          return "ok";

      }else{
          //must be for sale
          return "error:exists";
      }

    }
    function transferPattern(bytes32 patternid,address newowner,string message, uint8 v, bytes32 r, bytes32 s)
      public
      returns(string)
    {
      // just so we have somthing
      address oldowner = admin;

      //check that pattern in question has an owner
      require(Pattern[patternid].owner != address(0));

      //check that newowner is not no one
      require(newowner != address(0));

      //check if sender iis owner
      if(Pattern[patternid].owner == msg.sender){
        //if sender iiis owner
        oldowner = msg.sender;
      }else{
        // anyone else need to supply a new address signed by the old owner

        //generate the h for the new address
        bytes32 h = prefixedHash2(newowner);
        //check if eveything adds up.
        require(ecrecover(h, v, r, s) == Pattern[patternid].owner);
        oldowner = Pattern[patternid].owner;
      }

      //remove reference from old owner mapping
      removePatternUserIndex(oldowner,patternid);

      //update pattern owner and message
      Pattern[patternid].owner = newowner;
      Pattern[patternid].message = message;
      //add reference to owner map
      addPatternUserIndex(newowner,patternid);

      return "ok";

    }

    function changeMessage(bytes32 patternid,string message, uint8 v, bytes32 r, bytes32 s)
      public
      returns(string)
    {
      // just so we have somthing
      address owner = admin;

      //check that pattern in question has an owner
      require(Pattern[patternid].owner != address(0));

      //check if sender iis owner
      if(Pattern[patternid].owner == msg.sender){
        //if sender iiis owner
        owner = msg.sender;
      }else{
        // anyone else need to supply a new address signed by the old owner

        //generate the h for the new address
        bytes32 h = prefixedHash(message);
        owner = ecrecover(h, v, r, s);
      }

      require(Pattern[patternid].owner == owner);

      Pattern[patternid].message = message;

      return "ok";

    }

    function verifyOwner(bytes32 patternid, address owner, uint8 v, bytes32 r, bytes32 s)
      public
      view
      returns(bool)
    {
      //check that pattern in question has an owner
      require(Pattern[patternid].owner != address(0));

      //resolve owner address from signature
      bytes32 h = prefixedHash2(owner);
      address owner2 = ecrecover(h, v, r, s);

      require(owner2 == owner);

      //check if owner actually owns item in question
      if(Pattern[patternid].owner == owner2){
        return true;
      }else{
        return false;
      }
    }

    function prefixedHash(string message)
      private
      pure
      returns (bytes32)
    {
        bytes32 h = keccak256(abi.encodePacked(message));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }

    function prefixedHash2(address message)
      private
      pure
      returns (bytes32)
    {
        bytes32 h = keccak256(abi.encodePacked(message));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
    }


    function addPatternUserIndex(address account, bytes32 patternid)
      private
    {
        Patterns[account].push(patternid);
    }

    function removePatternUserIndex(address account, bytes32 patternid)
      private
    {
      require(Pattern[patternid].owner == account);
      for (uint i = 0; i<Patterns[account].length; i++){
          if(Patterns[account][i] == patternid){
              //replace with last entry
              Patterns[account][i] = Patterns[account][Patterns[account].length-1];
              //delete last
              delete Patterns[account][Patterns[account].length-1];
              //shorten array
              Patterns[account].length--;
          }
      }
    }

    function userHasPattern(address account)
      public
      view
      returns(bool)
    {
      if(Patterns[account].length >=1 )
      {
        return true;
      }else{
        return false;
      }
    }

    function emergency(address newa, uint8 v, bytes32 r, bytes32 s, uint8 v2, bytes32 r2, bytes32 s2)
      public
    {
      //generate hashes
      bytes32 h = prefixedHash2(newa);

      //check if admin and emergency_admin signed the messages
      require(ecrecover(h, v, r, s)==admin);
      require(ecrecover(h, v2, r2, s2)==emergency_admin);
      //set new admin
      admin = newa;
    }

    function changeInfo(string newinfo)
      public
      onlyAdmin
    {
      //only admin can call this.
      //require(msg.sender == admin); used modifier

      info = newinfo;
    }


    function toUpper(string str)
      pure
      private
      returns (string)
    {
      bytes memory bStr = bytes(str);
      bytes memory bLower = new bytes(bStr.length);
      for (uint i = 0; i < bStr.length; i++) {
        // lowercase character...
        if ((bStr[i] >= 65+32) && (bStr[i] <= 90+32)) {
          // So we remove 32 to make it uppercase
          bLower[i] = bytes1(int(bStr[i]) - 32);
        } else {
          bLower[i] = bStr[i];
        }
      }
      return string(bLower);
    }

}