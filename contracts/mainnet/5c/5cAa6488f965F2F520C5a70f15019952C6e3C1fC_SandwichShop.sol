pragma solidity ^0.4.11;

contract mortal
{
    address owner;

    function mortal() { owner = msg.sender; }
    function kill() { if(msg.sender == owner) selfdestruct(owner); }
}

contract SandwichShop is mortal
{

    struct Sandwich
    {
        uint sandwichID;
        string sandwichName;
        string sandwichDesc;
        uint calories;
        uint price;
        uint availableQuantity;
    }

    Sandwich[5] shopSandwich;

    function SandwichShop() public
    {
        shopSandwich[0].sandwichID = 100;
        shopSandwich[0].sandwichName = "100: Ham & Swiss";
        shopSandwich[0].sandwichDesc = "Ham Swiss Mustard Rye";
        shopSandwich[0].calories = 450;
        shopSandwich[0].price = 5;
        shopSandwich[0].availableQuantity = 200;

        shopSandwich[1].sandwichID = 101;
        shopSandwich[1].sandwichName = "101: Turkey & Pepperjack";
        shopSandwich[1].sandwichDesc = "Turkey Pepperjack Mayo White Bread";
        shopSandwich[1].calories = 500;
        shopSandwich[1].price = 5;
        shopSandwich[1].availableQuantity = 200;

        shopSandwich[2].sandwichID = 102;
        shopSandwich[2].sandwichName = "102: Roast Beef & American";
        shopSandwich[2].sandwichDesc = "Roast Beef Havarti Horseradish White Bread";
        shopSandwich[2].calories = 600;
        shopSandwich[2].price = 5;
        shopSandwich[2].availableQuantity = 200;

        shopSandwich[3].sandwichID = 103;
        shopSandwich[3].sandwichName = "103: Reuben";
        shopSandwich[3].sandwichDesc = "Corned Beef Sauerkraut Swiss Rye";
        shopSandwich[3].calories = 550;
        shopSandwich[3].price = 5;
        shopSandwich[3].availableQuantity = 200;

        shopSandwich[4].sandwichID = 104;
        shopSandwich[4].sandwichName = "104: Italian";
        shopSandwich[4].sandwichDesc = "Salami Peppers Provolone Oil Vinegar White";
        shopSandwich[4].calories = 500;
        shopSandwich[4].price = 5;
        shopSandwich[4].availableQuantity = 200;
    }

    function getMenu() constant returns (string, string, string, string, string)
    {
        return (shopSandwich[0].sandwichName, shopSandwich[1].sandwichName,
                shopSandwich[2].sandwichName, shopSandwich[3].sandwichName,
                shopSandwich[4].sandwichName );
    }

    function getSandwichInfoCaloriesPrice(uint _sandID) constant returns (string, string, uint, uint)
    {
        if( _sandID < 100 ) throw;
        if( _sandID > 104 ) throw;
        return (shopSandwich[_sandID].sandwichName, shopSandwich[_sandID].sandwichDesc,
                shopSandwich[_sandID].calories, shopSandwich[_sandID].price);

    }

}