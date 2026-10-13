import os
import shutil
import subprocess
import time
from tkinter import messagebox
import customtkinter as ctk

# Ruta de la carpeta compartida en tu servidor de red (192.168.1.10)
CARPETA_RED = r"\\192.168.1.10\Compartida_SISPA"
VERSION_REMOTE_URL = os.path.join(CARPETA_RED, "version.txt")
EXE_REMOTE_URL = os.path.join(CARPETA_RED, "SISPA.exe")

LOCAL_VERSION_FILE = "version.txt"
LOCAL_EXE_FILE = "SISPA.exe"


class LauncherApp(ctk.CTk):

  def __init__(self):
    super().__init__()
    self.title("Actualizador SISPA")
    self.geometry("400x220")
    self.resizable(False, False)
    self.configure(fg_color="#1f2937")

    self.lbl_estado = ctk.CTkLabel(
        self,
        text="Verificando actualizaciones...",
        font=("Segoe UI", 14, "bold"),
        text_color="#ffffff",
    )
    self.lbl_estado.pack(pady=35)

    self.progressbar = ctk.CTkProgressBar(self, width=300)
    self.progressbar.pack(pady=10)
    self.progressbar.set(0)

    self.after(1000, self.verificar_actualizacion)

  def verificar_actualizacion(self):
    try:
      self.lbl_estado.configure(text="Conectando con la red del hospital...")
      self.progressbar.set(0.3)

      if os.path.exists(VERSION_REMOTE_URL):
        with open(VERSION_REMOTE_URL, "r") as f:
          version_remota = f.read().strip()
      else:
        version_remota = "1.0"

      version_local = "1.0"
      if os.path.exists(LOCAL_VERSION_FILE):
        with open(LOCAL_VERSION_FILE, "r") as f:
          version_local = f.read().strip()

      self.progressbar.set(0.6)

      if version_remota != version_local or not os.path.exists(
          LOCAL_EXE_FILE
      ):
        self.lbl_estado.configure(
            text="Descargando nueva versión del sistema..."
        )
        shutil.copyfile(EXE_REMOTE_URL, LOCAL_EXE_FILE)

        with open(LOCAL_VERSION_FILE, "w") as f:
          f.write(version_remota)

      self.progressbar.set(1.0)
      self.lbl_estado.configure(text="¡Iniciando SISPA...")
      self.after(800, self.lanzar_sistema)

    except Exception as e:
      if os.path.exists(LOCAL_EXE_FILE):
        self.lbl_estado.configure(
            text="Modo sin conexión. Abriendo sistema..."
        )
        self.after(800, self.lanzar_sistema)
      else:
        messagebox.showerror(
            "Error de Conexión",
            "No se pudo conectar a la red ni encontrar una versión local"
            f" ejecutable.\nDetalle: {e}",
        )
        self.destroy()

  def lanzar_sistema(self):
    self.destroy()
    subprocess.Popen([LOCAL_EXE_FILE])


if __name__ == "__main__":
  app = LauncherApp()
  app.mainloop()
