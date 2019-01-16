pragma solidity ^0.4.24;

contract Solutionschains_by_KaranbirSekhri_Published_22November2018 {

string public Challenge; 
string public Useful_material;
string public Benefits;
string public Project_requestor_name;
string public Challenge_acceptor_name;
uint public Number_of_participants;
uint public Expected_reward_points;
uint public Timeline_for_completion_in_hours;
string public Solution_submission_link;
string public Winner;

function setChallenge(string _Challenge) public {
Challenge= _Challenge;
}

function setUseful_material(string _Useful_material) public {
Useful_material= _Useful_material;
}

function setBenfits(string _Benefits) public {
Benefits= _Benefits;
}

function setProject_requestor_name(string _Project_requestor_name) public {
Project_requestor_name= _Project_requestor_name;
}

function setChanllenge_acceptor_name(string _Challenge_acceptor_name) public {
Challenge_acceptor_name= _Challenge_acceptor_name;
}

function setexpected_reward_points(uint _Expected_reward_points) public {
Expected_reward_points= _Expected_reward_points;
}

function setTimeline_for_completion_in_hours(uint _Timeline_for_completion_in_hours) public {
Timeline_for_completion_in_hours= _Timeline_for_completion_in_hours;
}

function setSolution_submission_link(string _Solution_submission_link) public {
Solution_submission_link= _Solution_submission_link;
}

function setWinner(string _Winner) public {
Winner= _Winner;
}
}