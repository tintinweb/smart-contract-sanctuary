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
        shopSandwich[0].sandwichName = &quot;100: Ham & Swiss&quot;;
        shopSandwich[0].sandwichDesc = &quot;Ham Swiss Mustard Rye&quot;;
        shopSandwich[0].calories = 450;
        shopSandwich[0].price = 5;
        shopSandwich[0].availableQuantity = 200;

        shopSandwich[1].sandwichID = 101;
        shopSandwich[1].sandwichName = &quot;101: Turkey & Pepperjack&quot;;
        shopSandwich[1].sandwichDesc = &quot;Turkey Pepperjack Mayo White Bread&quot;;
        shopSandwich[1].calories = 500;
        shopSandwich[1].price = 5;
        shopSandwich[1].availableQuantity = 200;

        shopSandwich[2].sandwichID = 102;
        shopSandwich[2].sandwichName = &quot;102: Roast Beef & American&quot;;
        shopSandwich[2].sandwichDesc = &quot;Roast Beef Havarti Horseradish White Bread&quot;;
        shopSandwich[2].calories = 600;
        shopSandwich[2].price = 5;
        shopSandwich[2].availableQuantity = 200;

        shopSandwich[3].sandwichID = 103;
        shopSandwich[3].sandwichName = &quot;103: Reuben&quot;;
        shopSandwich[3].sandwichDesc = &quot;Corned Beef Sauerkraut Swiss Rye&quot;;
        shopSandwich[3].calories = 550;
        shopSandwich[3].price = 5;
        shopSandwich[3].availableQuantity = 200;

        shopSandwich[4].sandwichID = 104;
        shopSandwich[4].sandwichName = &quot;104: Italian&quot;;
        shopSandwich[4].sandwichDesc = &quot;Salami Peppers Provolone Oil Vinegar White&quot;;
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
        if( _sandID < 100 || _sandID > 104 )
        {
            return ( &quot;wrong ID&quot;, &quot;wrong ID&quot;, 0, 0);
        }
        else
        {
            return (shopSandwich[_sandID].sandwichName, shopSandwich[_sandID].sandwichDesc,
                shopSandwich[_sandID].calories, shopSandwich[_sandID].price);
        }

    }

}