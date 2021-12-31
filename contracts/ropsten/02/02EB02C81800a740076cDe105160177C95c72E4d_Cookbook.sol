// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Cookbook {

  struct Recipe {
      string ingredient_1;
      string ingredient_2;
      string result;
  }

  mapping(uint => Recipe) private _recipes;

  constructor() {
    addRecipe(0, unicode"🍄", unicode"💦", unicode"🍁");
  }

  function addRecipe(uint key, string memory ingredient_1, string memory ingredient_2, string memory result) public {
    Recipe memory recipe = _recipes[key];

    recipe.ingredient_1 = ingredient_1;
    recipe.ingredient_2 = ingredient_2;
    recipe.result = result;

    _recipes[key] = recipe;
  }

  function getRecipe(uint key) public returns (Recipe memory) {
    return _recipes[key];
  }


}