// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.8.11;

// Defines a contract named `HelloWorld`.
// A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract Grid {

   //Emitted when update function is called
   //Smart contract events are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening' for certain events and take action when they happen.
   event UpdatedGrid(uint x, uint y, uint newColor);

   // Declares a state variable `message` of type `string`.
   // State variables are variables whose values are permanently stored in contract storage. The keyword `public` makes variables accessible from outside a contract and creates a function that other contracts or clients can call to access the value.
   // string public message;
   uint[10][10] public grid;

   // Similar to many class-based object-oriented languages, a constructor is a special function that is only executed upon contract creation.
   // Constructors are used to initialize the contract's data. Learn more:https://solidity.readthedocs.io/en/v0.5.10/contracts.html#constructors
   // constructor(string memory initMessage) {

   //    // Accepts a string argument `initMessage` and sets the value into the contract's `message` storage variable).
   //    message = initMessage;
   // }

   // A public function that accepts a string argument and updates the `message` storage variable.
   function update(uint x, uint y, uint color) public {
      assert(0 <= x && x < 10 && 0 <= y && y < 10);
      assert(0 <= color && color < 10);
      grid[x][y] = color;
      emit UpdatedGrid(x, y, color);
   }

   function getGrid() public view returns(uint[10][10] memory) {
      return grid;
   }
}