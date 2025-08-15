// Definición del módulo
let app = angular.module('hemingwayApp', []);

app.service('dataService', function($http, $q) {
  let version = "v1";
  let uri = `http://localhost:3000/api/${version}`;

  this.getStudentsBy = (body) => {
    var deferred = $q.defer();
    $http.post(`${uri}/students-by`, body)
      .then(function(response) {
        deferred.resolve(response.data);
      }, function(error) {
        deferred.reject(error);
      });

    return deferred.promise;
  }

  this.getTypesBy = (body) => {
    var deferred = $q.defer();
    $http.post(`${uri}/types-by`, body)
      .then(function(response) {
        deferred.resolve(response.data);
      }, function(error) {
        deferred.reject(error);
      });

    return deferred.promise;
  }
});

// Definición de controlador principal
app.controller('mainController', ['$scope', 'dataService',   function($scope, dataService) {

  $scope.menu = [
    {
      id: "config",
      icon: "fas fa-cog",
      name: "Configuración Académica",
      description: "Inicialice las variables iniciales del aplicativo",
      selected: false
    },
    {
      id: "scores",
      icon: "fas fa-star",
      name: "Registro de Notas",
      description: "Seleccione una materia o período para gestionar las calificaciones",
      selected: false
    },
    {
      id: "students",
      icon: "fas fa-users",
      name: "Registro de Estudiantes",
      description: "Administre la información de los estudiantes",
      selected: false
    },
    {
      id: "descriptive_conclusions",
      icon: "fas fa-book",
      name: "Registro de Conclusiones Descriptivas",
      description: "Registre el logro, dificultad y recomendaciones de los estudiantes",
      selected: false
    },
    {
      id: "report_card",
      icon: "fas fa-list-check",
      name: "Boleta de Notas",
      description: "Visualice la boleta de notas de los estudiantes",
      selected: false
    },
  ];

  $scope.itemSelected = undefined;

  $scope.allStudents = [];
  $scope.genders = [];
  $scope.studentStatus = [];
  $scope.filter = {
    students: {
      text: undefined
    }
  };

  $scope.showForm = false;
  $scope.newItem;

  $scope.init = () => {
    console.log("Iniciando proyecto");
    $scope.getStudents();
  }

  $scope.selectItem = (item) => {
    $scope.itemSelected = item;
  }

  $scope.getStudents = async () => {
    try {
      let result = await dataService.getStudentsBy({filter: {}});
      console.log(result);
      if (!result.success) {
        Swal.fire({
          title: 'Error!',
          text: result.error,
          icon: 'error',
        });
        return;
      }
      $scope.allStudents = result.data;
    } catch (error) {
      console.log(error);
    }
  }

  $scope.toggleSidebar = (type, item = undefined) => {
    $scope.showForm = !$scope.showForm;
    switch (type) {
      case "student":
        $scope.newItem = {};
        if (item) {
          $scope.newItem = item;
          $scope.newItem.editing = true;
        }
        $scope.newItem.typeSelected = type;
        break;
    
      default:
        break;
    }
    // let sidebar = this.ElementRef.nativeElement.querySelector('#sidebar');
    // if (sidebar.classList.contains("open")) {
    //   this.ElementRef.nativeElement.querySelector('#sidebar').classList.remove('open');  
    //   this.ElementRef.nativeElement.querySelector('.overlay').classList.remove('active');
    //   this.newProduct = {};
    // } else {
    //   this.ElementRef.nativeElement.querySelector('#sidebar').classList.add('open');
    //   this.ElementRef.nativeElement.querySelector('.overlay').classList.add('active');
    //   if (product) {
    //     this.newProduct = JSON.parse(JSON.stringify(product));
    //     this.newProduct.editing = true;
    //   }
    // }
  }

}]);
