from datetime import datetime
import os
import tempfile
from tkinter import filedialog, messagebox, ttk
import customtkinter as ctk
import mysql.connector
import pandas as pd

ctk.set_appearance_mode("Light")
ctk.set_default_color_theme("blue")


class SispaApp(ctk.CTk):

  def __init__(self):
    super().__init__()

    self.title("Sistema SISPA - Hospital General Teziutlán")
    self.geometry("1500x980")
    self.minsize(1250, 880)

    self.configure(fg_color="#d0e8ff")

    # Inicializar la Base de Datos central de MariaDB en red
    self.init_database()

    # Base de datos global independiente por área
    self.registros_usg = []
    self.pacientes_usg = []

    self.registros_tac = []
    self.pacientes_tac = []

    self.registros_rx = []
    self.pacientes_rx = []

    # Listas dinámicas de estudios
    self.estudios_usg_lista = [
        "ABDOMEN",
        "PELVICO",
        "OBSTRETICO",
        "CUELLO",
        "MAMAS",
        "DOPPLER",
        "TESTICULARES",
        "TIROIDEOS",
    ]
    self.estudios_tac_lista = [
        "CRANEO SIMPLE",
        "S Y C DE CRANEO",
        "TX SIMPLE",
        "TX S Y C",
        "ABD. SUP. SIMPLE",
        "ABD. SUP. S Y C",
        "ABD. INF. SIMPLE",
        "ABD. INF. S Y C",
    ]
    self.estudios_rx_lista = [
        "CRANEO",
        "TORAX",
        "ABDOMEN",
        "COLUMNA",
        "MIEMBROS SUP.",
        "MIEMBROS INF.",
        "ES. CONTR",
    ]

    # Lista base oficial de personal
    self.lista_personal = [
        "T.R. BLANCA ISABEL APARICIO ZAPATA",
        "T.R. JOSE ADRIAN GARCIA SANCHEZ",
        "T.R. JESUS DEL CARMEN CAMPOS",
        "T.R. MARIO RAMOS DE LA CRUZ",
        "T.R. JOSE LUIS LOPEZ ALFONSO",
        "T.R. ANALLELY MELGAREJO BALTAZAR",
        "T.R. OSMAR J. RODRIGUEZ PAZOS",
        "T.R. ULISES G. ROMERO GARCIA",
        "T.R. ALAN GERARDO GONZALEZ JUAREZ",
        "T.R. BETSABE SARAY RIVERA MARTINEZ",
        "DRA. ESTHER NERI RUBIO",
        "DR. JUAN IVAN RIVERA VELAZQUEZ",
        "DR. DAVID CESAR MORENO RAMOS",
    ]

    # Barra superior con el Título Principal y controles globales
    self.barra_superior = ctk.CTkFrame(self, fg_color="transparent", height=50)
    self.barra_superior.pack(fill="x", padx=20, pady=(10, 0))

    lbl_titulo_principal = ctk.CTkLabel(
        self.barra_superior,
        text="HOSPITAL GENERAL DE TEZIUTLÁN",
        font=ctk.CTkFont(size=20, weight="bold"),
        text_color=("#111111", "#ffffff"),
    )
    lbl_titulo_principal.pack(side="left", padx=5)

    # Botón de Copia de Seguridad
    btn_backup = ctk.CTkButton(
        self.barra_superior,
        text="💾 Copia de Seguridad",
        fg_color="#007AFF",
        hover_color="#0056B3",
        text_color="#ffffff",
        corner_radius=16,
        height=36,
        command=self.hacer_copia_seguridad,
    )
    btn_backup.pack(side="left", padx=10)

    # Botón de Imprimir
    btn_imprimir = ctk.CTkButton(
        self.barra_superior,
        text="🖨️ Imprimir Reporte Actual",
        fg_color="#34C759",
        hover_color="#28A745",
        text_color="#ffffff",
        corner_radius=16,
        height=36,
        command=self.imprimir_reporte,
    )
    btn_imprimir.pack(side="left", padx=10)

    self.seg_modo = ctk.CTkSegmentedButton(
        self.barra_superior, values=["Claro", "Oscuro"], command=self.cambiar_modo_apariencia
    )
    self.seg_modo.pack(side="right", padx=5)
    self.seg_modo.set("Claro")

    lbl_modo = ctk.CTkLabel(
        self.barra_superior,
        text="Apariencia",
        font=ctk.CTkFont(size=13, weight="bold"),
    )
    lbl_modo.pack(side="right", padx=5)

    # Contenedor principal con pestañas
    self.tabview = ctk.CTkTabview(
        self,
        corner_radius=16,
        fg_color=("#d0e8ff", "#1f2937"),
        segmented_button_fg_color=("#b0d4ff", "#111827"),
        segmented_button_selected_color=("#34C759", "#28A745"),
        segmented_button_selected_hover_color=("#28A745", "#218838"),
        command=self.on_tab_changed,
    )
    self.tabview.pack(fill="both", expand=True, padx=15, pady=10)

    self.tabview._segmented_button.configure(
        font=ctk.CTkFont(size=13, weight="bold"),
        text_color=("#000000", "#ffffff"),
    )

    self.tab_usg = self.tabview.add("Ultrasonido (USG)")
    self.tab_tac = self.tabview.add("Tomografía (TAC)")
    self.tab_rx = self.tabview.add("Rayos X (T.R.)")

    self.tab_prod_usg = self.tabview.add("Matriz USG")
    self.tab_prod_tac = self.tabview.add("Matriz TAC")
    self.tab_prod_rx = self.tabview.add("Matriz RX")
    self.tab_prod_general = self.tabview.add("PROD. General")

    self.vars_usg = {}
    self.vars_tac = {}
    self.vars_rx = {}

    self.setup_usg_tab(self.tab_usg)
    self.setup_tac_tab(self.tab_tac)
    self.setup_rx_tab(self.tab_rx)

    self.setup_prod_usg_tab(self.tab_prod_usg)
    self.setup_prod_tac_tab(self.tab_prod_tac)
    self.setup_prod_rx_tab(self.tab_prod_rx)
    self.setup_prod_general_tab(self.tab_prod_general)

    # Cargar los datos desde el servidor al iniciar la app
    self.cargar_datos_desde_servidor()

    # Iniciar ciclo de sincronización automática en tiempo real cada 4 segundos
    self.iniciar_sincronizacion_en_tiempo_real()

  def init_database(self):
    try:
      self.conexion = mysql.connector.connect(
          host="192.168.1.10",
          user="root",
          password="1234",
          database="hospital_sispa",
          autocommit=True,
      )
      self.cursor = self.conexion.cursor()
      self.cursor.execute("""
                CREATE TABLE IF NOT EXISTS registros_estudios (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    grupo_id VARCHAR(50),
                    area VARCHAR(50),
                    fecha VARCHAR(20),
                    medico VARCHAR(150),
                    estudio VARCHAR(150),
                    clasificacion VARCHAR(50),
                    edad INT,
                    sexo VARCHAR(20)
                )
            """)
      try:
        self.cursor.execute(
            "ALTER TABLE registros_estudios ADD COLUMN grupo_id VARCHAR(50)"
        )
      except Exception:
        pass
    except mysql.connector.Error as err:
      messagebox.showerror(
          "Error de Conexión", f"No se pudo conectar a la base de datos {err}"
      )

  def iniciar_sincronizacion_en_tiempo_real(self):
    try:
      self.cargar_datos_desde_servidor(silencioso=True)
    except Exception:
      pass
    self.after(4000, self.iniciar_sincronizacion_en_tiempo_real)

  def hacer_copia_seguridad(self):
    try:
      query = "SELECT area, fecha, medico, estudio, clasificacion, edad, sexo FROM registros_estudios"
      df = pd.read_sql(query, self.conexion)

      if df.empty:
        messagebox.showwarning(
            "Aviso", "No hay registros en la base de datos para respaldar."
        )
        return

      archivo_destino = filedialog.asksaveasfilename(
          defaultextension=".xlsx",
          filetypes=[("Archivos de Excel", "*.xlsx"), ("Todos los archivos", "*.*")],
          title="Guardar Copia de Seguridad",
          initialfile=f"Respaldo_SISPA_{datetime.now().strftime('%d_%m_%Y_%H%M')}.xlsx",
      )

      if archivo_destino:
        df.to_excel(archivo_destino, index=False)
        messagebox.showinfo(
            "Éxito",
            f"Copia de seguridad guardada correctamente en:\n{archivo_destino}",
        )
    except Exception as err:
      messagebox.showerror(
          "Error", f"No se pudo generar la copia de seguridad: {err}"
      )

  def imprimir_reporte(self):
    pestana_actual = self.tabview.get()
    tree_a_imprimir = None
    titulo_area = ""

    if pestana_actual == "Ultrasonido (USG)":
      tree_a_imprimir = self.tree_usg
      titulo_area = "Ultrasonido (USG)"
    elif pestana_actual == "Tomografía (TAC)":
      tree_a_imprimir = self.tree_tac
      titulo_area = "Tomografía (TAC)"
    elif pestana_actual == "Rayos X (T.R.)":
      tree_a_imprimir = self.tree_rx
      titulo_area = "Rayos X (T.R.)"
    elif pestana_actual == "Matriz USG":
      tree_a_imprimir = self.tree_prod_usg
      titulo_area = "Matriz Oficial de Producción - USG"
    elif pestana_actual == "Matriz TAC":
      tree_a_imprimir = self.tree_prod_tac
      titulo_area = "Matriz Oficial de Producción - TAC"
    elif pestana_actual == "Matriz RX":
      tree_a_imprimir = self.tree_prod_rx
      titulo_area = "Matriz Oficial de Producción - RX"
    elif pestana_actual == "PROD. General":
      tree_a_imprimir = self.tree_prod_general
      titulo_area = "Estadística General Consolidada"

    if not tree_a_imprimir:
      messagebox.showwarning("Aviso", "Selecciona una pestaña válida para imprimir.")
      return

    filas = tree_a_imprimir.get_children()
    if not filas:
      messagebox.showwarning("Aviso", f"No hay datos en '{titulo_area}' para imprimir.")
      return

    columnas = [tree_a_imprimir.heading(col)["text"] for col in tree_a_imprimir["columns"]]
    datos = [tree_a_imprimir.item(row)["values"] for row in filas]

    html_content = f"""
        <html>
        <head>
            <meta charset="utf-8">
            <title>Reporte SISPA - {titulo_area}</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; color: #111; }}
                h2 {{ text-align: center; color: #007AFF; margin-bottom: 5px; }}
                h4 {{ text-align: center; color: #555; margin-top: 0; }}
                table {{ width: 100%; border-collapse: collapse; margin-top: 20px; }}
                th, td {{ border: 1px solid #ccc; padding: 8px 12px; text-align: center; font-size: 12px; }}
                th {{ background-color: #007AFF; color: white; font-weight: bold; }}
                tr:nth-child(even) {{ background-color: #f9f9f9; }}
            </style>
        </head>
        <body onload="window.print();">
            <h2>HOSPITAL GENERAL DE TEZIUTLÁN</h2>
            <h4>Área: {titulo_area} | Fecha de Impresión: {datetime.now().strftime('%d/%m/%Y %H:%M')}</h4>
            <table>
                <thead>
                    <tr>{''.join(f'<th>{col}</th>' for col in columnas)}</tr>
                </thead>
                <tbody>
                    {''.join(f"<tr>{''.join(f'<td>{val}</td>' for val in fila)}</tr>" for fila in datos)}
                </tbody>
            </table>
        </body>
        </html>
        """

    try:
      with tempfile.NamedTemporaryFile(delete=False, suffix=".html", mode="w", encoding="utf-8") as f:
        f.write(html_content)
        temp_filename = f.name

      import webbrowser

      webbrowser.open(f"file:///{os.path.abspath(temp_filename)}")
    except Exception as err:
      messagebox.showerror("Error", f"No se pudo mandar a imprimir el reporte: {err}")

  def cargar_datos_desde_servidor(self, silencioso=False):
    try:
      if not self.conexion.is_connected():
        self.conexion.reconnect(attempts=3, delay=2)
        self.cursor = self.conexion.cursor()

      self.conexion.commit()

      self.cursor.execute(
          "SELECT id, grupo_id, area, fecha, medico, estudio, clasificacion, edad, sexo"
          " FROM registros_estudios"
      )
      resultados = self.cursor.fetchall()

      self.registros_usg.clear()
      self.pacientes_usg.clear()
      self.registros_tac.clear()
      self.pacientes_tac.clear()
      self.registros_rx.clear()
      self.pacientes_rx.clear()

      for tree in [
          getattr(self, "tree_usg", None),
          getattr(self, "tree_tac", None),
          getattr(self, "tree_rx", None),
      ]:
        if tree:
          for row in tree.get_children():
            tree.delete(row)

      for fila in resultados:
        reg_id, grupo_id, area, fecha, medico, estudio, clasificacion, edad, sexo = fila

        if not grupo_id:
          grupo_id = f"legacy_{reg_id}"

        reg_dict = {
            "ID": reg_id,
            "Grupo": grupo_id,
            "Fecha": fecha,
            "Área / Médico": medico,
            "Estudio": estudio,
            "Clasificación": clasificacion,
            "Cantidad": 1,
        }

        pac_dict = {
            "ID": reg_id,
            "Grupo": grupo_id,
            "Fecha": fecha,
            "Medico": medico,
            "Edad": edad,
            "Sexo": sexo,
            "Procedencia": clasificacion,
            "Estudios_Asociados": 1,
        }

        if area == "USG":
          self.registros_usg.append(reg_dict)
          self.pacientes_usg.append(pac_dict)
          if hasattr(self, "tree_usg"):
            self.tree_usg.insert(
                "",
                "end",
                values=(fecha, medico, estudio, clasificacion, edad, sexo),
                tags=(str(reg_id),),
            )
        elif area == "TAC":
          self.registros_tac.append(reg_dict)
          self.pacientes_tac.append(pac_dict)
          if hasattr(self, "tree_tac"):
            self.tree_tac.insert(
                "",
                "end",
                values=(fecha, medico, estudio, clasificacion, edad, sexo),
                tags=(str(reg_id),),
            )
        elif area == "RX":
          self.registros_rx.append(reg_dict)
          self.pacientes_rx.append(pac_dict)
          if hasattr(self, "tree_rx"):
            self.tree_rx.insert(
                "",
                "end",
                values=(fecha, medico, estudio, clasificacion, edad, sexo),
                tags=(str(reg_id),),
            )

      pestana_actual = self.tabview.get()
      if pestana_actual == "PROD. General":
        self.calcular_estadistica_general()
      elif pestana_actual == "Matriz USG":
        self.calcular_estadistica_matriz(
            self.registros_usg, self.pacientes_usg, self.tree_prod_usg
        )
      elif pestana_actual == "Matriz TAC":
        self.calcular_estadistica_matriz(
            self.registros_tac, self.pacientes_tac, self.tree_prod_tac
        )
      elif pestana_actual == "Matriz RX":
        self.calcular_estadistica_matriz(
            self.registros_rx, self.pacientes_rx, self.tree_prod_rx
        )

    except mysql.connector.Error as err:
      if not silencioso:
        print(f"Error al sincronizar datos del servidor: {err}")

  def cambiar_modo_apariencia(self, seleccion):
    if seleccion == "Claro":
      ctk.set_appearance_mode("Light")
      self.configure(fg_color="#d0e8ff")
    elif seleccion == "Oscuro":
      ctk.set_appearance_mode("Dark")
      self.configure(fg_color="#111827")

  def crear_burbuja_ios(
      self, parent, texto, color_bg, row_idx, col_idx, text_color="#1c1c1e"
  ):
    burbuja = ctk.CTkFrame(parent, fg_color=color_bg, corner_radius=18, height=38)
    burbuja.grid(row=row_idx, column=col_idx, padx=8, pady=6, sticky="w")
    burbuja.grid_propagate(False)

    lbl = ctk.CTkLabel(
        burbuja,
        text=texto,
        font=ctk.CTkFont(size=13, weight="bold"),
        text_color=text_color,
    )
    lbl.pack(padx=14, pady=8, expand=True)
    return burbuja

  def crear_campo_fecha_ios(self, parent, row_idx, col_idx=0):
    self.crear_burbuja_ios(
        parent, "Fecha", "#007AFF", row_idx, col_idx, text_color="#ffffff"
    )
    entry_fecha = ctk.CTkEntry(
        parent,
        width=130,
        height=38,
        corner_radius=18,
        border_width=2,
        border_color="#007AFF",
        font=("Segoe UI", 11),
    )
    entry_fecha.insert(0, datetime.now().strftime("%d/%m/%Y"))
    entry_fecha.grid(row=row_idx, column=col_idx + 1, padx=8, pady=6, sticky="w")
    return entry_fecha

  def crear_selector_personal_ios(self, parent, row_idx, col_idx):
    self.crear_burbuja_ios(
        parent, "Personal", "#34C759", row_idx, col_idx, text_color="#000000"
    )
    combo = ctk.CTkComboBox(
        parent,
        values=self.lista_personal,
        width=310,
        height=38,
        corner_radius=18,
        border_width=2,
        border_color="#34C759",
        font=("Segoe UI", 11),
    )
    combo.grid(row=row_idx, column=col_idx + 1, padx=8, pady=6, sticky="w")
    if self.lista_personal:
      combo.set(self.lista_personal[0])
    return combo

  def crear_selector_clasificacion_ios(self, parent, row_idx, col_idx):
    self.crear_burbuja_ios(
        parent,
        "Clasificación",
        "#AF52DE",
        row_idx,
        col_idx,
        text_color="#ffffff",
    )
    combo = ctk.CTkComboBox(
        parent,
        values=["EXT", "HOSP", "URG"],
        width=130,
        height=38,
        corner_radius=18,
        border_width=2,
        border_color="#AF52DE",
        font=("Segoe UI", 11),
    )
    combo.grid(row=row_idx, column=col_idx + 1, padx=8, pady=6, sticky="w")
    combo.set("EXT")
    return combo

  def crear_campo_edad_ios(self, parent, row_idx, col_idx=0):
    self.crear_burbuja_ios(
        parent, "Edad", "#FF9500", row_idx, col_idx, text_color="#000000"
    )
    entry_edad = ctk.CTkEntry(
        parent,
        width=130,
        height=38,
        corner_radius=18,
        border_width=2,
        border_color="#FF9500",
        placeholder_text="Ej. 35",
        font=("Segoe UI", 11),
    )
    entry_edad.grid(row=row_idx, column=col_idx + 1, padx=8, pady=6, sticky="w")
    return entry_edad

  def crear_selector_sexo_ios(self, parent, row_idx, col_idx):
    self.crear_burbuja_ios(
        parent, "Sexo", "#FF2D55", row_idx, col_idx, text_color="#ffffff"
    )
    combo = ctk.CTkComboBox(
        parent,
        values=["HOMBRE", "MUJER"],
        width=140,
        height=38,
        corner_radius=18,
        border_width=2,
        border_color="#FF2D55",
        font=("Segoe UI", 11),
    )
    combo.grid(row=row_idx, column=col_idx + 1, padx=8, pady=6, sticky="w")
    combo.set("HOMBRE")
    return combo

  def actualizar_todos_combos(self):
    for combo in [self.combo_usg, self.combo_tac, self.combo_rx]:
      combo.configure(values=self.lista_personal)
      if self.lista_personal:
        combo.set(self.lista_personal[0])

  def gestionar_personal_dialogo(self):
    dialogo = ctk.CTkToplevel(self)
    dialogo.title("Gestión de Personal")
    dialogo.geometry("450x420")
    dialogo.attributes("-topmost", True)

    lbl = ctk.CTkLabel(
        dialogo,
        text="Administrar Médicos y Técnicos",
        font=ctk.CTkFont(size=16, weight="bold"),
        text_color=("#111111", "#ffffff"),
    )
    lbl.pack(pady=15)

    combo_gestor = ctk.CTkComboBox(
        dialogo, values=self.lista_personal, width=360, height=38, corner_radius=18
    )
    combo_gestor.pack(pady=10)

    entry_nombre = ctk.CTkEntry(
        dialogo,
        placeholder_text="Escribir nombre completo...",
        width=360,
        height=38,
        corner_radius=18,
    )
    entry_nombre.pack(pady=10)

    def agregar_nuevo():
      nuevo = entry_nombre.get().strip().upper()
      if nuevo and nuevo not in self.lista_personal:
        self.lista_personal.append(nuevo)
        self.actualizar_todos_combos()
        combo_gestor.configure(values=self.lista_personal)
        entry_nombre.delete(0, "end")
        messagebox.showinfo("Éxito", "Personal agregado correctamente.")
      else:
        messagebox.showwarning("Aviso", "El nombre está vacío o ya existe.")

    def editar_seleccionado():
      seleccion = combo_gestor.get()
      editado = entry_nombre.get().strip().upper()
      if seleccion and editado:
        idx = self.lista_personal.index(seleccion)
        self.lista_personal[idx] = editado
        self.actualizar_todos_combos()
        combo_gestor.configure(values=self.lista_personal)
        messagebox.showinfo("Éxito", "Personal actualizado.")
      else:
        messagebox.showwarning(
            "Aviso", "Selecciona y escribe un nombre válido para editar."
        )

    def eliminar_seleccionado():
      seleccion = combo_gestor.get()
      if seleccion in self.lista_personal:
        if len(self.lista_personal) > 1:
          self.lista_personal.remove(seleccion)
          self.actualizar_todos_combos()
          combo_gestor.configure(values=self.lista_personal)
          messagebox.showinfo("Éxito", "Personal eliminado.")
        else:
          messagebox.showwarning(
              "Aviso", "Debe quedar al menos un elemento en la lista."
          )

    ctk.CTkButton(
        dialogo,
        text="➕ Añadir Nuevo",
        fg_color="#34C759",
        hover_color="#28A745",
        corner_radius=18,
        height=38,
        command=agregar_nuevo,
        width=360,
    ).pack(pady=6)
    ctk.CTkButton(
        dialogo,
        text="✏️ Editar Seleccionado",
        fg_color="#007AFF",
        hover_color="#0056B3",
        corner_radius=18,
        height=38,
        command=editar_seleccionado,
        width=360,
    ).pack(pady=6)
    ctk.CTkButton(
        dialogo,
        text="🗑️ Eliminar Seleccionado",
        fg_color="#FF3B30",
        hover_color="#D32F2F",
        corner_radius=18,
        height=38,
        command=eliminar_seleccionado,
        width=360,
    ).pack(pady=6)

  def gestionar_estudios_dialogo(
      self,
      lista_estudios,
      frame_grid,
      vars_dict,
      callback_refrescar,
      area_nombre,
  ):
    dialogo = ctk.CTkToplevel(self)
    dialogo.title(f"Añadir estudios - {area_nombre}")
    dialogo.geometry("450x440")
    dialogo.attributes("-topmost", True)

    lbl = ctk.CTkLabel(
        dialogo,
        text=f"Administrar Estudios ({area_nombre})",
        font=ctk.CTkFont(size=16, weight="bold"),
        text_color=("#111111", "#ffffff"),
    )
    lbl.pack(pady=15)

    combo_gestor = ctk.CTkComboBox(
        dialogo,
        values=lista_estudios,
        width=360,
        height=38,
        corner_radius=18,
        font=("Segoe UI", 11),
    )
    combo_gestor.pack(pady=10)

    entry_estudio = ctk.CTkEntry(
        dialogo,
        placeholder_text="Escribir nombre del estudio...",
        width=360,
        height=38,
        corner_radius=18,
        font=("Segoe UI", 11),
    )
    entry_estudio.pack(pady=10)

    def agregar_estudio():
      nuevo = entry_estudio.get().strip().upper()
      if nuevo and nuevo not in lista_estudios:
        lista_estudios.append(nuevo)
        callback_refrescar(frame_grid, vars_dict, lista_estudios)
        combo_gestor.configure(values=lista_estudios)
        entry_estudio.delete(0, "end")
        messagebox.showinfo(
            "Éxito", f"Estudio '{nuevo}' agregado correctamente."
        )
      else:
        messagebox.showwarning(
            "Aviso", "El nombre está vacío o ya existe en la lista."
        )

    def editar_estudio():
      seleccion = combo_gestor.get()
      editado = entry_estudio.get().strip().upper()
      if seleccion and editado:
        if seleccion in lista_estudios:
          idx = lista_estudios.index(seleccion)
          lista_estudios[idx] = editado
          callback_refrescar(frame_grid, vars_dict, lista_estudios)
          combo_gestor.configure(values=lista_estudios)
          entry_estudio.delete(0, "end")
          messagebox.showinfo("Éxito", "Estudio actualizado correctamente.")
      else:
        messagebox.showwarning(
            "Aviso",
            "Selecciona un estudio existente y escribe el nuevo nombre.",
        )

    def eliminar_estudio():
      seleccion = combo_gestor.get()
      if seleccion in lista_estudios:
        if len(lista_estudios) > 1:
          lista_estudios.remove(seleccion)
          callback_refrescar(frame_grid, vars_dict, lista_estudios)
          combo_gestor.configure(values=lista_estudios)
          if lista_estudios:
            combo_gestor.set(lista_estudios[0])
          messagebox.showinfo("Éxito", f"Estudio '{seleccion}' eliminado.")
        else:
          messagebox.showwarning(
              "Aviso", "Debe quedar al menos un estudio en la lista."
          )

    ctk.CTkButton(
        dialogo,
        text="➕ Añadir Nuevo",
        fg_color="#34C759",
        hover_color="#28A745",
        text_color="#ffffff",
        corner_radius=18,
        height=38,
        command=agregar_estudio,
        width=360,
        font=("Segoe UI", 12, "bold"),
    ).pack(pady=6)
    ctk.CTkButton(
        dialogo,
        text="✏️ Editar Seleccionado",
        fg_color="#007AFF",
        hover_color="#0056B3",
        text_color="#ffffff",
        corner_radius=18,
        height=38,
        command=editar_estudio,
        width=360,
        font=("Segoe UI", 12, "bold"),
    ).pack(pady=6)
    ctk.CTkButton(
        dialogo,
        text="🗑️ Eliminar Seleccionado",
        fg_color="#FF3B30",
        hover_color="#D32F2F",
        text_color="#ffffff",
        corner_radius=18,
        height=38,
        command=eliminar_estudio,
        width=360,
        font=("Segoe UI", 12, "bold"),
    ).pack(pady=6)

  def crear_tabla_estandar(self, parent, area_nombre):
    frame_tabla = ctk.CTkFrame(
        parent, corner_radius=18, fg_color=("#ffffff", "#1e1e24")
    )
    frame_tabla.pack(fill="both", expand=True, padx=12, pady=10)

    cols = (
        "Fecha",
        "Responsable",
        "Estudio Realizado",
        "Clasificación",
        "Edad",
        "Sexo",
    )

    style = ttk.Style()
    style.theme_use("default")

    style.configure(
        "Custom.Treeview",
        background="#ffffff",
        foreground="#1c1c1e",
        rowheight=45,
        fieldbackground="#ffffff",
        font=("Segoe UI", 13),
    )
    style.configure(
        "Custom.Treeview.Heading",
        background="#007AFF",
        foreground="#ffffff",
        font=("Segoe UI", 13, "bold"),
    )
    style.map(
        "Custom.Treeview",
        background=[("selected", "#34C759")],
        foreground=[("selected", "#ffffff")],
    )

    tree_frame = ctk.CTkFrame(frame_tabla, fg_color="transparent")
    tree_frame.pack(fill="both", expand=True, padx=10, pady=10)

    tree = ttk.Treeview(
        tree_frame, columns=cols, show="headings", height=8, style="Custom.Treeview"
    )

    anchos = [130, 360, 340, 130, 90, 110]
    for col, ancho in zip(cols, anchos):
      tree.heading(col, text=col)
      tree.column(col, width=ancho, anchor="center")

    tree.pack(side="left", fill="both", expand=True)

    scrollbar = ttk.Scrollbar(tree_frame, orient="vertical", command=tree.yview)
    scrollbar.pack(side="right", fill="y")
    tree.configure(yscrollcommand=scrollbar.set)

    tree.bind(
        "<Double-1>",
        lambda event: self.abrir_editor_registro(tree, area_nombre),
    )

    return tree

  def abrir_editor_registro(self, tree_widget, area_nombre):
    item_seleccionado = tree_widget.selection()
    if not item_seleccionado:
      return

    item_id = item_seleccionado[0]
    tags = tree_widget.item(item_id, "tags")
    if not tags:
      return

    db_id = tags[0]
    valores_actuales = tree_widget.item(item_id, "values")

    dialogo = ctk.CTkToplevel(self)
    dialogo.title(f"Gestionar Registro - {area_nombre}")
    dialogo.geometry("450x520")
    dialogo.attributes("-topmost", True)

    lbl = ctk.CTkLabel(
        dialogo,
        text="Editar o Eliminar Registro",
        font=ctk.CTkFont(size=16, weight="bold"),
        text_color=("#111111", "#ffffff"),
    )
    lbl.pack(pady=15)

    ctk.CTkLabel(dialogo, text="Fecha (DD/MM/YYYY):", font=("Segoe UI", 11)).pack(
        anchor="w", padx=45
    )
    entry_f = ctk.CTkEntry(dialogo, width=360, height=34, corner_radius=12)
    entry_f.insert(0, valores_actuales[0])
    entry_f.pack(pady=4)

    ctk.CTkLabel(dialogo, text="Responsable:", font=("Segoe UI", 11)).pack(
        anchor="w", padx=45
    )
    combo_r = ctk.CTkComboBox(
        dialogo, values=self.lista_personal, width=360, height=34, corner_radius=12
    )
    combo_r.set(valores_actuales[1])
    combo_r.pack(pady=4)

    ctk.CTkLabel(dialogo, text="Estudio Realizado:", font=("Segoe UI", 11)).pack(
        anchor="w", padx=45
    )
    if area_nombre == "USG":
      est_lista = self.estudios_usg_lista
    elif area_nombre == "TAC":
      est_lista = self.estudios_tac_lista
    else:
      est_lista = self.estudios_rx_lista

    combo_e = ctk.CTkComboBox(
        dialogo, values=est_lista, width=360, height=34, corner_radius=12
    )
    combo_e.set(valores_actuales[2])
    combo_e.pack(pady=4)

    ctk.CTkLabel(dialogo, text="Clasificación:", font=("Segoe UI", 11)).pack(
        anchor="w", padx=45
    )
    combo_c = ctk.CTkComboBox(
        dialogo,
        values=["EXT", "HOSP", "URG"],
        width=360,
        height=34,
        corner_radius=12,
    )
    combo_c.set(valores_actuales[3])
    combo_c.pack(pady=4)

    frame_es = ctk.CTkFrame(dialogo, fg_color="transparent")
    frame_es.pack(pady=4)

    ctk.CTkLabel(frame_es, text="Edad:", font=("Segoe UI", 11)).pack(
        side="left", padx=5
    )
    entry_edad = ctk.CTkEntry(
        frame_es, width=110, height=34, corner_radius=12
    )
    entry_edad.insert(0, str(valores_actuales[4]))
    entry_edad.pack(side="left", padx=5)

    ctk.CTkLabel(frame_es, text="Sexo:", font=("Segoe UI", 11)).pack(
        side="left", padx=5
    )
    combo_sexo = ctk.CTkComboBox(
        frame_es, values=["HOMBRE", "MUJER"], width=130, height=34, corner_radius=12
    )
    combo_sexo.set(valores_actuales[5])
    combo_sexo.pack(side="left", padx=5)

    def guardar_cambios():
      nueva_fecha = entry_f.get().strip()
      nuevo_resp = combo_r.get()
      nuevo_est = combo_e.get()
      nueva_clas = combo_c.get()
      nueva_edad = entry_edad.get().strip()
      nuevo_sexo = combo_sexo.get()

      if not nueva_edad.isdigit():
        messagebox.showwarning("Aviso", "La edad debe ser un número válido.")
        return

      try:
        self.cursor.execute(
            "UPDATE registros_estudios SET fecha = %s, medico = %s, estudio ="
            " %s, clasificacion = %s, edad = %s, sexo = %s WHERE id = %s",
            (
                nueva_fecha,
                nuevo_resp,
                nuevo_est,
                nueva_clas,
                int(nueva_edad),
                nuevo_sexo,
                db_id,
            ),
        )
        self.conexion.commit()
        self.cargar_datos_desde_servidor(silencioso=True)
        dialogo.destroy()
        messagebox.showinfo("Éxito", "Registro actualizado correctamente.")
      except mysql.connector.Error as err:
        messagebox.showerror(
            "Error", f"No se pudo actualizar el registro: {err}"
        )

    def eliminar_registro():
      if messagebox.askyesno(
          "Confirmar Eliminación",
          "¿Estás seguro de eliminar este registro permanentemente?",
      ):
        try:
          self.cursor.execute(
              "DELETE FROM registros_estudios WHERE id = %s", (db_id,)
          )
          self.conexion.commit()
          self.cargar_datos_desde_servidor(silencioso=True)
          dialogo.destroy()
          messagebox.showinfo("Éxito", "Registro eliminado correctamente.")
        except mysql.connector.Error as err:
          messagebox.showerror("Error", f"No se pudo eliminar el registro: {err}")

    btn_guardar = ctk.CTkButton(
        dialogo,
        text="💾 Guardar Cambios",
        fg_color="#007AFF",
        hover_color="#0056B3",
        text_color="#ffffff",
        corner_radius=18,
        height=36,
        command=guardar_cambios,
        width=360,
    )
    btn_guardar.pack(pady=8)

    btn_eliminar = ctk.CTkButton(
        dialogo,
        text="🗑️ Eliminar Registro",
        fg_color="#FF3B30",
        hover_color="#D32F2F",
        text_color="#ffffff",
        corner_radius=18,
        height=36,
        command=eliminar_registro,
        width=360,
    )
    btn_eliminar.pack(pady=4)

  def refrescar_grid_estudios(self, frame_grid, vars_dict, lista_estudios):
    for widget in frame_grid.winfo_children():
      widget.destroy()

    vars_dict.clear()

    for i, est in enumerate(lista_estudios):
      row = i // 3
      col = i % 3
      var = ctk.BooleanVar(value=False)
      chk = ctk.CTkCheckBox(
          frame_grid,
          text=est,
          variable=var,
          font=ctk.CTkFont(size=13, weight="bold"),
          checkbox_width=24,
          checkbox_height=24,
          corner_radius=8,
      )
      chk.grid(row=row, column=col, padx=25, pady=10, sticky="w")
      vars_dict[est] = var

  def setup_usg_tab(self, parent):
    top_frame = ctk.CTkFrame(
        parent, corner_radius=18, fg_color=("#e8e8ed", "#2c2c2e")
    )
    top_frame.pack(fill="x", padx=12, pady=(10, 4))

    entry_fecha = self.crear_campo_fecha_ios(top_frame, row_idx=0, col_idx=0)
    self.combo_usg = self.crear_selector_personal_ios(
        top_frame, row_idx=0, col_idx=2
    )
    combo_tipo = self.crear_selector_clasificacion_ios(
        top_frame, row_idx=0, col_idx=4
    )

    btn_gestionar = ctk.CTkButton(
        top_frame,
        text="⚙️ Personal",
        fg_color="#5AC8FA",
        hover_color="#45A4D0",
        text_color="#000000",
        corner_radius=18,
        height=38,
        width=120,
        font=("Segoe UI", 11, "bold"),
        command=self.gestionar_personal_dialogo,
    )
    btn_gestionar.grid(row=0, column=6, padx=10, pady=8)

    entry_edad = self.crear_campo_edad_ios(top_frame, row_idx=1, col_idx=0)
    combo_sexo = self.crear_selector_sexo_ios(top_frame, row_idx=1, col_idx=2)

    grid_frame = ctk.CTkFrame(
        parent, corner_radius=18, fg_color=("#f9f9fb", "#1c1c1e")
    )
    grid_frame.pack(fill="x", padx=12, pady=4)

    btn_nuevo_estudio = ctk.CTkButton(
        top_frame,
        text="⚙️ Añadir estudios",
        fg_color="#FF9500",
        hover_color="#E08500",
        text_color="#000000",
        corner_radius=18,
        height=38,
        width=170,
        font=("Segoe UI", 12, "bold"),
        command=lambda: self.gestionar_estudios_dialogo(
            self.estudios_usg_lista,
            grid_frame,
            self.vars_usg,
            self.refrescar_grid_estudios,
            "USG",
        ),
    )
    btn_nuevo_estudio.grid(row=1, column=4, padx=10, pady=8, sticky="w")

    self.refrescar_grid_estudios(
        grid_frame, self.vars_usg, self.estudios_usg_lista
    )
    self.tree_usg = self.crear_tabla_estandar(parent, "USG")

    btn_agregar = ctk.CTkButton(
        parent,
        text="🚀 Registrar Estudios y Paciente (Automático)",
        corner_radius=22,
        fg_color="#34C759",
        hover_color="#28A745",
        font=ctk.CTkFont(size=15, weight="bold"),
        height=46,
        command=lambda: self.procesar_y_guardar_area(
            self.combo_usg.get(),
            entry_fecha.get(),
            combo_tipo.get(),
            entry_edad.get(),
            combo_sexo.get(),
            self.vars_usg,
            self.tree_usg,
            entry_edad,
            "USG",
        ),
    )
    btn_agregar.pack(pady=8)

  def setup_tac_tab(self, parent):
    top_frame = ctk.CTkFrame(
        parent, corner_radius=18, fg_color=("#e8e8ed", "#2c2c2e")
    )
    top_frame.pack(fill="x", padx=12, pady=(10, 4))

    entry_fecha = self.crear_campo_fecha_ios(top_frame, row_idx=0, col_idx=0)
    self.combo_tac = self.crear_selector_personal_ios(
        top_frame, row_idx=0, col_idx=2
    )
    combo_tipo = self.crear_selector_clasificacion_ios(
        top_frame, row_idx=0, col_idx=4
    )

    btn_gestionar = ctk.CTkButton(
        top_frame,
        text="⚙️ Personal",
        fg_color="#5AC8FA",
        hover_color="#45A4D0",
        text_color="#000000",
        corner_radius=18,
        height=38,
        width=120,
        font=("Segoe UI", 11, "bold"),
        command=self.gestionar_personal_dialogo,
    )
    btn_gestionar.grid(row=0, column=6, padx=10, pady=8)

    entry_edad = self.crear_campo_edad_ios(top_frame, row_idx=1, col_idx=0)
    combo_sexo = self.crear_selector_sexo_ios(top_frame, row_idx=1, col_idx=2)

    grid_frame = ctk.CTkFrame(
        parent, corner_radius=18, fg_color=("#f9f9fb", "#1c1c1e")
    )
    grid_frame.pack(fill="x", padx=12, pady=4)

    btn_nuevo_estudio = ctk.CTkButton(
        top_frame,
        text="⚙️ Añadir estudios",
        fg_color="#FF9500",
        hover_color="#E08500",
        text_color="#000000",
        corner_radius=18,
        height=38,
        width=170,
        font=("Segoe UI", 12, "bold"),
        command=lambda: self.gestionar_estudios_dialogo(
            self.estudios_tac_lista,
            grid_frame,
            self.vars_tac,
            self.refrescar_grid_estudios,
            "TAC",
        ),
    )
    btn_nuevo_estudio.grid(row=1, column=4, padx=10, pady=8, sticky="w")

    self.refrescar_grid_estudios(
        grid_frame, self.vars_tac, self.estudios_tac_lista
    )
    self.tree_tac = self.crear_tabla_estandar(parent, "TAC")

    btn_agregar = ctk.CTkButton(
        parent,
        text="🚀 Registrar Estudios y Paciente (Automático)",
        corner_radius=22,
        fg_color="#34C759",
        hover_color="#28A745",
        font=ctk.CTkFont(size=15, weight="bold"),
        height=46,
        command=lambda: self.procesar_y_guardar_area(
            self.combo_tac.get(),
            entry_fecha.get(),
            combo_tipo.get(),
            entry_edad.get(),
            combo_sexo.get(),
            self.vars_tac,
            self.tree_tac,
            entry_edad,
            "TAC",
        ),
    )
    btn_agregar.pack(pady=8)

  def setup_rx_tab(self, parent):
    top_frame = ctk.CTkFrame(
        parent, corner_radius=18, fg_color=("#e8e8ed", "#2c2c2e")
    )
    top_frame.pack(fill="x", padx=12, pady=(10, 4))

    entry_fecha = self.crear_campo_fecha_ios(top_frame, row_idx=0, col_idx=0)
    self.combo_rx = self.crear_selector_personal_ios(
        top_frame, row_idx=0, col_idx=2
    )
    combo_proc = self.crear_selector_clasificacion_ios(
        top_frame, row_idx=0, col_idx=4
    )

    btn_gestionar = ctk.CTkButton(
        top_frame,
        text="⚙️ Personal",
        fg_color="#5AC8FA",
        hover_color="#45A4D0",
        text_color="#000000",
        corner_radius=18,
        height=38,
        width=120,
        font=("Segoe UI", 11, "bold"),
        command=self.gestionar_personal_dialogo,
    )
    btn_gestionar.grid(row=0, column=6, padx=10, pady=8)

    entry_edad = self.crear_campo_edad_ios(top_frame, row_idx=1, col_idx=0)
    combo_sexo = self.crear_selector_sexo_ios(top_frame, row_idx=1, col_idx=2)

    grid_frame = ctk.CTkFrame(
        parent, corner_radius=18, fg_color=("#f9f9fb", "#1c1c1e")
    )
    grid_frame.pack(fill="x", padx=12, pady=4)

    btn_nuevo_estudio = ctk.CTkButton(
        top_frame,
        text="⚙️ Añadir estudios",
        fg_color="#FF9500",
        hover_color="#E08500",
        text_color="#000000",
        corner_radius=18,
        height=38,
        width=170,
        font=("Segoe UI", 12, "bold"),
        command=lambda: self.gestionar_estudios_dialogo(
            self.estudios_rx_lista,
            grid_frame,
            self.vars_rx,
            self.refrescar_grid_estudios,
            "Rayos X",
        ),
    )
    btn_nuevo_estudio.grid(row=1, column=4, padx=10, pady=8, sticky="w")

    self.refrescar_grid_estudios(
        grid_frame, self.vars_rx, self.estudios_rx_lista
    )
    self.tree_rx = self.crear_tabla_estandar(parent, "RX")

    btn_agregar = ctk.CTkButton(
        parent,
        text="🚀 Registrar Estudios y Paciente (Automático)",
        corner_radius=22,
        fg_color="#34C759",
        hover_color="#28A745",
        font=ctk.CTkFont(size=15, weight="bold"),
        height=46,
        command=lambda: self.procesar_y_guardar_area(
            self.combo_rx.get(),
            entry_fecha.get(),
            combo_proc.get(),
            entry_edad.get(),
            combo_sexo.get(),
            self.vars_rx,
            self.tree_rx,
            entry_edad,
            "RX",
        ),
    )
    btn_agregar.pack(pady=8)

  def setup_prod_usg_tab(self, parent):
    lbl = ctk.CTkLabel(
        parent,
        text="📈 Matriz Oficial de Producción - ULTRASONIDO",
        font=ctk.CTkFont(size=18, weight="bold"),
    )
    lbl.pack(pady=8)

    frame_prod = ctk.CTkFrame(
        parent, corner_radius=16, fg_color=("#f0f0f5", "#1a1a1e")
    )
    frame_prod.pack(fill="both", expand=True, padx=12, pady=10)

    cols = (
        "MÉDICO / T.R.",
        "TOTAL ESTUDIOS",
        "TOTAL PERSONAS",
        "EXT. ESTUDIOS",
        "EXT. PERSONAS",
        "HOSP. ESTUDIOS",
        "HOSP. PERSONAS",
        "URG. ESTUDIOS",
        "URG. PERSONAS",
    )

    style = ttk.Style()
    style.theme_use("default")
    style.configure(
        "Custom.Treeview",
        background="#ffffff",
        foreground="#111111",
        rowheight=60,
        fieldbackground="#ffffff",
        font=("Segoe UI", 16),
    )
    style.configure(
        "Custom.Treeview.Heading",
        font=("Segoe UI", 14, "bold"),
        background="#007AFF",
        foreground="#ffffff",
    )

    self.tree_prod_usg = ttk.Treeview(
        frame_prod, columns=cols, show="headings", height=12, style="Custom.Treeview"
    )
    anchos = [360, 130, 130, 120, 120, 120, 120, 120, 120]
    for col, ancho in zip(cols, anchos):
      self.tree_prod_usg.heading(col, text=col)
      self.tree_prod_usg.column(col, width=ancho, anchor="center")

    self.tree_prod_usg.pack(
        side="left", fill="both", expand=True, padx=8, pady=8
    )
    scrollbar = ttk.Scrollbar(
        frame_prod, orient="vertical", command=self.tree_prod_usg.yview
    )
    scrollbar.pack(side="right", fill="y", pady=8)
    self.tree_prod_usg.configure(yscrollcommand=scrollbar.set)

  def setup_prod_tac_tab(self, parent):
    lbl = ctk.CTkLabel(
        parent,
        text="📈 Matriz Oficial de Producción - TOMOGRAFÍA (TAC)",
        font=ctk.CTkFont(size=18, weight="bold"),
    )
    lbl.pack(pady=8)

    frame_prod = ctk.CTkFrame(
        parent, corner_radius=16, fg_color=("#f0f0f5", "#1a1a1e")
    )
    frame_prod.pack(fill="both", expand=True, padx=12, pady=10)

    cols = (
        "MÉDICO / T.R.",
        "TOTAL ESTUDIOS",
        "TOTAL PERSONAS",
        "EXT. ESTUDIOS",
        "EXT. PERSONAS",
        "HOSP. ESTUDIOS",
        "HOSP. PERSONAS",
        "URG. ESTUDIOS",
        "URG. PERSONAS",
    )

    style = ttk.Style()
    style.theme_use("default")
    style.configure(
        "Custom.Treeview",
        background="#ffffff",
        foreground="#111111",
        rowheight=60,
        fieldbackground="#ffffff",
        font=("Segoe UI", 16),
    )
    style.configure(
        "Custom.Treeview.Heading",
        font=("Segoe UI", 14, "bold"),
        background="#007AFF",
        foreground="#ffffff",
    )

    self.tree_prod_tac = ttk.Treeview(
        frame_prod, columns=cols, show="headings", height=12, style="Custom.Treeview"
    )
    anchos = [360, 130, 130, 120, 120, 120, 120, 120, 120]
    for col, ancho in zip(cols, anchos):
      self.tree_prod_tac.heading(col, text=col)
      self.tree_prod_tac.column(col, width=ancho, anchor="center")

    self.tree_prod_tac.pack(
        side="left", fill="both", expand=True, padx=8, pady=8
    )
    scrollbar = ttk.Scrollbar(
        frame_prod, orient="vertical", command=self.tree_prod_tac.yview
    )
    scrollbar.pack(side="right", fill="y", pady=8)
    self.tree_prod_tac.configure(yscrollcommand=scrollbar.set)

  def setup_prod_rx_tab(self, parent):
    lbl = ctk.CTkLabel(
        parent,
        text="📈 Matriz Oficial de Producción - RAYOS X",
        font=ctk.CTkFont(size=18, weight="bold"),
    )
    lbl.pack(pady=8)

    frame_prod = ctk.CTkFrame(
        parent, corner_radius=16, fg_color=("#f0f0f5", "#1a1a1e")
    )
    frame_prod.pack(fill="both", expand=True, padx=12, pady=10)

    cols = (
        "MÉDICO / T.R.",
        "TOTAL ESTUDIOS",
        "TOTAL PERSONAS",
        "EXT. ESTUDIOS",
        "EXT. PERSONAS",
        "HOSP. ESTUDIOS",
        "HOSP. PERSONAS",
        "URG. ESTUDIOS",
        "URG. PERSONAS",
    )

    style = ttk.Style()
    style.theme_use("default")
    style.configure(
        "Custom.Treeview",
        background="#ffffff",
        foreground="#111111",
        rowheight=60,
        fieldbackground="#ffffff",
        font=("Segoe UI", 16),
    )
    style.configure(
        "Custom.Treeview.Heading",
        font=("Segoe UI", 14, "bold"),
        background="#007AFF",
        foreground="#ffffff",
    )

    self.tree_prod_rx = ttk.Treeview(
        frame_prod, columns=cols, show="headings", height=12, style="Custom.Treeview"
    )
    anchos = [360, 130, 130, 120, 120, 120, 120, 120, 120]
    for col, ancho in zip(cols, anchos):
      self.tree_prod_rx.heading(col, text=col)
      self.tree_prod_rx.column(col, width=ancho, anchor="center")

    self.tree_prod_rx.pack(
        side="left", fill="both", expand=True, padx=8, pady=8
    )
    scrollbar = ttk.Scrollbar(
        frame_prod, orient="vertical", command=self.tree_prod_rx.yview
    )
    scrollbar.pack(side="right", fill="y", pady=8)
    self.tree_prod_rx.configure(yscrollcommand=scrollbar.set)

  def setup_prod_general_tab(self, parent):
    lbl = ctk.CTkLabel(
        parent,
        text=(
            "📊 Estadística General (Consolidado por Médico / T.R. y Proyecto)"
        ),
        font=ctk.CTkFont(size=18, weight="bold"),
    )
    lbl.pack(pady=8)

    frame_prod = ctk.CTkFrame(
        parent, corner_radius=16, fg_color=("#f0f0f5", "#1a1a1e")
    )
    frame_prod.pack(fill="both", expand=True, padx=12, pady=10)

    cols = (
        "MÉDICO / T.R.",
        "ÁREA / PROYECTO",
        "TOTAL ESTUDIOS",
        "TOTAL PERSONAS",
        "EXT. ESTUDIOS",
        "EXT. PERSONAS",
        "HOSP. ESTUDIOS",
        "HOSP. PERSONAS",
        "URG. ESTUDIOS",
        "URG. PERSONAS",
    )

    style = ttk.Style()
    style.theme_use("default")
    style.configure(
        "Custom.Treeview",
        background="#ffffff",
        foreground="#111111",
        rowheight=60,
        fieldbackground="#ffffff",
        font=("Segoe UI", 15),
    )
    style.configure(
        "Custom.Treeview.Heading",
        font=("Segoe UI", 12, "bold"),
        background="#007AFF",
        foreground="#ffffff",
    )

    self.tree_prod_general = ttk.Treeview(
        frame_prod, columns=cols, show="headings", height=12, style="Custom.Treeview"
    )
    anchos = [290, 180, 120, 120, 105, 105, 105, 105, 105, 105]
    for col, ancho in zip(cols, anchos):
      self.tree_prod_general.heading(col, text=col)
      self.tree_prod_general.column(col, width=ancho, anchor="center")

    self.tree_prod_general.pack(
        side="left", fill="both", expand=True, padx=8, pady=8
    )
    scrollbar = ttk.Scrollbar(
        frame_prod, orient="vertical", command=self.tree_prod_general.yview
    )
    scrollbar.pack(side="right", fill="y", pady=8)
    self.tree_prod_general.configure(yscrollcommand=scrollbar.set)

  def on_tab_changed(self):
    self.cargar_datos_desde_servidor(silencioso=True)

  def procesar_y_guardar_area(
      self,
      medico,
      fecha,
      clasificacion,
      edad,
      sexo,
      dic_vars,
      tree_widget,
      entry_edad,
      area,
  ):
    if not edad.isdigit():
      messagebox.showwarning(
          "Advertencia",
          "Por favor ingresa una edad válida en números para el paciente.",
      )
      return

    estudios_seleccionados = [est for est, var in dic_vars.items() if var.get()]

    if not estudios_seleccionados:
      messagebox.showwarning(
          "Advertencia", "Por favor marca al menos un estudio en las casillas."
      )
      return

    try:
      import uuid

      grupo_id = str(uuid.uuid4())

      for estudio in estudios_seleccionados:
        self.cursor.execute(
            "INSERT INTO registros_estudios (grupo_id, area, fecha, medico,"
            " estudio, clasificacion, edad, sexo) VALUES (%s, %s, %s, %s, %s,"
            " %s, %s, %s)",
            (
                grupo_id,
                area,
                fecha,
                medico.strip(),
                estudio,
                clasificacion.strip(),
                int(edad),
                sexo,
            ),
        )
      self.conexion.commit()

      self.cargar_datos_desde_servidor(silencioso=True)

      for est in estudios_seleccionados:
        dic_vars[est].set(False)

      entry_edad.delete(0, "end")
      messagebox.showinfo(
          "Éxito",
          f"¡Se registraron {len(estudios_seleccionados)} estudio(s) de {area}"
          " correctamente en el servidor!",
      )

    except mysql.connector.Error as err:
      messagebox.showerror(
          "Error de Base de Datos", f"No se pudo guardar el registro: {err}"
      )

  def calcular_estadistica_matriz(self, registros, pacientes, tree_widget):
    for row in tree_widget.get_children():
      tree_widget.delete(row)

    df_est = (
        pd.DataFrame(registros)
        if registros
        else pd.DataFrame(
            columns=["Área / Médico", "Clasificación", "Cantidad", "Grupo"]
        )
    )
    df_pac = (
        pd.DataFrame(pacientes)
        if pacientes
        else pd.DataFrame(columns=["Medico", "Procedencia", "Grupo"])
    )

    t_est, t_pac = 0, 0
    ext_est_tot, ext_pac_tot = 0, 0
    hosp_est_tot, hosp_pac_tot = 0, 0
    urg_est_tot, urg_pac_tot = 0, 0

    for medico in self.lista_personal:
      sub_est = (
          df_est[df_est["Área / Médico"] == medico]
          if not df_est.empty
          else pd.DataFrame()
      )
      sub_pac = (
          df_pac[df_pac["Medico"] == medico]
          if not df_pac.empty
          else pd.DataFrame()
      )

      ext_est = (
          int(
              sub_est[sub_est["Clasificación"] == "EXT"]["Cantidad"].sum()
          )
          if not sub_est.empty
          else 0
      )
      ext_pac = (
          sub_pac[sub_pac["Procedencia"] == "EXT"]["Grupo"].nunique()
          if not sub_pac.empty
          else 0
      )

      hosp_est = (
          int(
              sub_est[sub_est["Clasificación"] == "HOSP"]["Cantidad"].sum()
          )
          if not sub_est.empty
          else 0
      )
      hosp_pac = (
          sub_pac[sub_pac["Procedencia"] == "HOSP"]["Grupo"].nunique()
          if not sub_pac.empty
          else 0
      )

      urg_est = (
          int(
              sub_est[sub_est["Clasificación"] == "URG"]["Cantidad"].sum()
          )
          if not sub_est.empty
          else 0
      )
      urg_pac = (
          sub_pac[sub_pac["Procedencia"] == "URG"]["Grupo"].nunique()
          if not sub_pac.empty
          else 0
      )

      tot_est = ext_est + hosp_est + urg_est
      tot_pac = ext_pac + hosp_pac + urg_pac

      t_est += tot_est
      t_pac += tot_pac
      ext_est_tot += ext_est
      ext_pac_tot += ext_pac
      hosp_est_tot += hosp_est
      hosp_pac_tot += hosp_pac
      urg_est_tot += urg_est
      urg_pac_tot += urg_pac

      tree_widget.insert(
          "",
          "end",
          values=(
              medico,
              tot_est,
              tot_pac,
              ext_est,
              ext_pac,
              hosp_est,
              hosp_pac,
              urg_est,
              urg_pac,
          ),
      )

    tree_widget.insert(
        "",
        "end",
        values=(
            "TOTAL",
            t_est,
            t_pac,
            ext_est_tot,
            ext_pac_tot,
            hosp_est_tot,
            hosp_pac_tot,
            urg_est_tot,
            urg_pac_tot,
        ),
    )

  def calcular_estadistica_general(self):
    for row in self.tree_prod_general.get_children():
      self.tree_prod_general.delete(row)

    areas = [
        ("Ultrasonido (USG)", self.registros_usg, self.pacientes_usg),
        ("Tomografía (TAC)", self.registros_tac, self.pacientes_tac),
        ("Rayos X (T.R.)", self.registros_rx, self.pacientes_rx),
    ]

    tot_g_est, tot_g_pac = 0, 0
    ext_g_est, ext_g_pac = 0, 0
    hosp_g_est, hosp_g_pac = 0, 0
    urg_g_est, urg_g_pac = 0, 0

    for medico in self.lista_personal:
      for nombre_area, regs, pacs in areas:
        df_est = (
            pd.DataFrame(regs)
            if regs
            else pd.DataFrame(
                columns=["Área / Médico", "Clasificación", "Cantidad", "Grupo"]
            )
        )
        df_pac = (
            pd.DataFrame(pacs)
            if pacs
            else pd.DataFrame(columns=["Medico", "Procedencia", "Grupo"])
        )

        sub_est = (
            df_est[df_est["Área / Médico"] == medico]
            if not df_est.empty
            else pd.DataFrame()
        )
        sub_pac = (
            df_pac[df_pac["Medico"] == medico]
            if not df_pac.empty
            else pd.DataFrame()
        )

        ext_est = (
            int(
                sub_est[sub_est["Clasificación"] == "EXT"]["Cantidad"].sum()
            )
            if not sub_est.empty
            else 0
        )
        ext_pac = (
            sub_pac[sub_pac["Procedencia"] == "EXT"]["Grupo"].nunique()
            if not sub_pac.empty
            else 0
        )

        hosp_est = (
            int(
                sub_est[sub_est["Clasificación"] == "HOSP"]["Cantidad"].sum()
            )
            if not sub_est.empty
            else 0
        )
        hosp_pac = (
            sub_pac[sub_pac["Procedencia"] == "HOSP"]["Grupo"].nunique()
            if not sub_pac.empty
            else 0
        )

        urg_est = (
            int(
                sub_est[sub_est["Clasificación"] == "URG"]["Cantidad"].sum()
            )
            if not sub_est.empty
            else 0
        )
        urg_pac = (
            sub_pac[sub_pac["Procedencia"] == "URG"]["Grupo"].nunique()
            if not sub_pac.empty
            else 0
        )

        t_est = ext_est + hosp_est + urg_est
        t_pac = ext_pac + hosp_pac + urg_pac

        if t_est > 0 or t_pac > 0:
          tot_g_est += t_est
          tot_g_pac += t_pac
          ext_g_est += ext_est
          ext_g_pac += ext_pac
          hosp_g_est += hosp_est
          hosp_g_pac += hosp_pac
          urg_g_est += urg_est
          urg_g_pac += urg_pac

          self.tree_prod_general.insert(
              "",
              "end",
              values=(
                  medico,
                  nombre_area,
                  t_est,
                  t_pac,
                  ext_est,
                  ext_pac,
                  hosp_est,
                  hosp_pac,
                  urg_est,
                  urg_pac,
              ),
          )

    self.tree_prod_general.insert(
        "",
        "end",
        values=(
            "TOTAL GENERAL",
            "",
            tot_g_est,
            tot_g_pac,
            ext_g_est,
            ext_g_pac,
            hosp_g_est,
            hosp_g_pac,
            urg_g_est,
            urg_g_pac,
        ),
    )


if __name__ == "__main__":
  app = SispaApp()
  app.mainloop()