import setuptools

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setuptools.setup(
    name="topicosmi",
    version="0.0.1",
    author="Rodrigo Meneses",
    author_email="rodrigo.menesesufc@gmail.com",
    description="Disciplina Tópicos Avançados de Matemátida Industrial",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/rodrigofmeneses/Topicos-MI",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    packages=setuptools.find_packages(),
    python_requires='>=3.6',
)
