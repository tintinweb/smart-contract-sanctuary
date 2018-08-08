pragma solidity ^0.4.18;

contract Story {
  address public developer = 0x003BDf0961d5D6cda616ac8812B63E6De5910bc9;

  event StoryUpdate(string decided, string chapter);

  string[] public prompts;
  uint public iteration = 0;
  string[] public history; //choice history

  mapping (uint => uint) public votes;
  uint public numVotes = 0;
  string[] public choices;

  function Story() public {
    prompts.push("..Lambo drifting across the lunar sand.. the smell of burning garlic awakens you from your slumber. You stumble towards the burning. A plate of roasted garlic, burnt to a crisp atop your new BREAD-CHAMP mining rig. Before you can take another whiff, your BREAD-CHAMP catches fire. Molten solder melts a hole through your apartment floor and your rig plummets ten feet. A flicker on your smartwatch tells you that all crypto has jumped another 10 points towards the Moon! You begin to notice your headache. Then you notice your doge, crying in the hallway. He needs a walk but your crypto is melting and you almost had enough to buy 1 Lambo tire.");
    choices.push("Take your doge for a walk.");
    choices.push("Follow your crypto&#39;s dip into the earth.");
  }

  modifier onlyDev() {
    require(msg.sender == developer);
    _;
  }

  function castVote(uint optionNumber, uint clientStoryIndex) public payable  {
    require(clientStoryIndex == iteration);
    require(optionNumber == 0 || optionNumber == 1);
    votes[optionNumber] = votes[optionNumber] + msg.value;
    numVotes = numVotes + 1;
  }

  function next(string newPrompt, string choice0, string choice1, string newPrompt2, string choice20, string choice21) public onlyDev returns (bool) {
    if (votes[0] >= votes[1]) {
      history.push(choices[0]);
      StoryUpdate(choices[0], newPrompt);
      prompts.push(newPrompt);
      choices[0] = choice0;
      choices[1] = choice1;
    } else {
      history.push(choices[1]);
      StoryUpdate(choices[0], newPrompt);
      prompts.push(newPrompt2);
      choices[0] = choice20;
      choices[1] = choice21;
    }

    votes[0] = 0;
    votes[1] = 0;
    numVotes = 0;

    iteration = iteration + 1;
    
    payout();

    return true;
  }

  function payout() public {
    require(this.balance >= 1000000000000000);
    developer.transfer(this.balance);
  }
}