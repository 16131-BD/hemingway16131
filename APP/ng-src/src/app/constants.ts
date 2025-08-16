import Swal, { SweetAlertOptions } from "sweetalert2";

export const API_URI = 'http://localhost:3000/api/v1';

export function messageAlert(title: any, message: string, icon: string) {
  let icons: any = {
    'success': 'success',
    'error': 'error',
    'warning': 'warning',
    'info': 'info',
  }
  Swal.fire({
    text: message,
    icon: icons[icon]
  });
}