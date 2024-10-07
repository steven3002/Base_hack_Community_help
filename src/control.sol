// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;




contract Counter {
    struct ClassroomInstance {
        address instructor;
        string title;
        string description;
        string ipfsHash;  // IPFS hash of the off-chain content (topics, materials)
        address[] students; // List of students' addresses
    }
    
    // Mapping from classroom ID to ClassroomInstance
    mapping(uint => ClassroomInstance) public classrooms;

    
    // Store the count of classrooms
    uint public classroomCount = 0;

    // Mapping of students' progress in each classroom
    mapping(uint => mapping(address => uint8)) public progress; // classroomID => student => progress percentage

    // Event to be emitted when a new classroom is created
    event ClassroomCreated(
        uint classroomID,
        address indexed instructor,
        string title,
        string description,
        string ipfsHash
    );

    // Event to be emitted when a student enrolls
    event StudentEnrolled(
        uint classroomID,
        address indexed student
    );

    // Event to be emitted when a student's progress is updated
    event ProgressUpdated(
        uint classroomID,
        address indexed student,
        uint8 progress
    );

    // Create a new classroom
    function createClassroom(
        string memory _title,
        string memory _description,
        string memory _ipfsHash
    ) public {
        ClassroomInstance storage newClassroom = classrooms[classroomCount];
        newClassroom.instructor = msg.sender;
        newClassroom.title = _title;
        newClassroom.description = _description;
        newClassroom.ipfsHash = _ipfsHash;

        emit ClassroomCreated(classroomCount, msg.sender, _title, _description, _ipfsHash);

        classroomCount++;
    }

    // Enroll a student in the classroom
    function enrollStudent(uint _classroomID) public {
        require(_classroomID < classroomCount, "Classroom does not exist");
        ClassroomInstance storage classroom = classrooms[_classroomID];

        classroom.students.push(msg.sender);

        emit StudentEnrolled(_classroomID, msg.sender);
    }

    // Update the progress of a student (percentage)
    function updateProgress(uint _classroomID, uint8 _progress) public {
        require(_classroomID < classroomCount, "Classroom does not exist");
        require(_progress <= 100, "Progress must be between 0 and 100");
        
        progress[_classroomID][msg.sender] = _progress;

        emit ProgressUpdated(_classroomID, msg.sender, _progress);
    }

    // Get students of a classroom
    function getStudents(uint _classroomID) public view returns (address[] memory) {
        require(_classroomID < classroomCount, "Classroom does not exist");
        return classrooms[_classroomID].students;
    }

    // Get progress of a student in a specific classroom
    function getProgress(uint _classroomID, address _student) public view returns (uint8) {
        require(_classroomID < classroomCount, "Classroom does not exist");
        return progress[_classroomID][_student];
    }
}

