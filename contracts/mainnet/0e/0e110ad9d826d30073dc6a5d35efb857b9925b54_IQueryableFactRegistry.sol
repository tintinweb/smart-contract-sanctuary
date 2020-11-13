pragma solidity ^0.5.2;

import "./IFactRegistry.sol";

/*
  Extends the IFactRegistry interface with a query method that indicates
  whether the fact registry has successfully registered any fact or is still empty of such facts.
*/
contract IQueryableFactRegistry is IFactRegistry {

    /*
      Returns true if at least one fact has been registered.
    */
    function hasRegisteredFact()
        external view
        returns(bool);

}
